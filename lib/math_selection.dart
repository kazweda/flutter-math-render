import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Lets a formula take part in an enclosing [SelectionArea] as one unit, and
/// copy as [text] (its TeX).
///
/// [Math] doesn't implement [Selectable], so without this a [SelectionArea]
/// skips formulas: they aren't highlighted and are left out of the copy.
/// Outside a [SelectionArea] (or [SelectableRegion]) this returns [child]
/// unchanged.
///
/// Based on the [SelectableRegion] API sample in the Flutter repository
/// (`examples/api/lib/material/selectable_region/selectable_region.0.dart`).
class MathSelectionAdapter extends StatelessWidget {
  const MathSelectionAdapter({
    super.key,
    required this.text,
    required this.child,
  });

  /// What a selection containing this formula copies, such as `$x^2$`.
  final String text;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
    if (registrar == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: _MathSelectable(registrar: registrar, text: text, child: child),
    );
  }
}

class _MathSelectable extends SingleChildRenderObjectWidget {
  const _MathSelectable({
    required this.registrar,
    required this.text,
    required Widget super.child,
  });

  final SelectionRegistrar registrar;
  final String text;

  @override
  _RenderMathSelectable createRenderObject(BuildContext context) {
    return _RenderMathSelectable(
      DefaultSelectionStyle.of(context).selectionColor!,
      registrar: registrar,
      text: text,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMathSelectable renderObject,
  ) {
    renderObject
      ..selectionColor = DefaultSelectionStyle.of(context).selectionColor!
      ..registrar = registrar
      ..text = text;
  }
}

/// A [Selectable] that is either wholly selected or not selected at all.
class _RenderMathSelectable extends RenderProxyBox
    with Selectable, SelectionRegistrant {
  _RenderMathSelectable(
    this._selectionColor, {
    required SelectionRegistrar registrar,
    required this.text,
  }) : _geometry = ValueNotifier<SelectionGeometry>(_noSelection) {
    this.registrar = registrar;
    _geometry.addListener(markNeedsPaint);
  }

  static const SelectionGeometry _noSelection = SelectionGeometry(
    status: SelectionStatus.none,
    hasContent: true,
  );

  final ValueNotifier<SelectionGeometry> _geometry;

  String text;

  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  @override
  void addListener(VoidCallback listener) => _geometry.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _geometry.removeListener(listener);

  @override
  SelectionGeometry get value => _geometry.value;

  @override
  List<Rect> get boundingBoxes => <Rect>[paintBounds];

  Rect get _bounds => Offset.zero & size;

  Offset? _start;
  Offset? _end;

  void _updateGeometry() {
    if (_start == null ||
        _end == null ||
        _bounds.intersect(Rect.fromPoints(_start!, _end!)).isEmpty) {
      _geometry.value = _noSelection;
      return;
    }
    final SelectionPoint first = SelectionPoint(
      localPosition: _bounds.bottomLeft,
      lineHeight: size.height,
      handleType: TextSelectionHandleType.left,
    );
    final SelectionPoint second = SelectionPoint(
      localPosition: _bounds.bottomRight,
      lineHeight: size.height,
      handleType: TextSelectionHandleType.right,
    );
    final bool reversed = _start!.dy != _end!.dy
        ? _start!.dy > _end!.dy
        : _start!.dx > _end!.dx;
    _geometry.value = SelectionGeometry(
      status: SelectionStatus.uncollapsed,
      hasContent: true,
      startSelectionPoint: reversed ? second : first,
      endSelectionPoint: reversed ? first : second,
      selectionRects: <Rect>[_bounds],
    );
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    SelectionResult result = SelectionResult.none;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final Offset point = globalToLocal(
          (event as SelectionEdgeUpdateEvent).globalPosition,
        );
        final Offset adjusted = SelectionUtils.adjustDragOffset(_bounds, point);
        if (event.type == SelectionEventType.startEdgeUpdate) {
          _start = adjusted;
        } else {
          _end = adjusted;
        }
        result = SelectionUtils.getResultBasedOnRect(_bounds, point);
      case SelectionEventType.clear:
        _start = _end = null;
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
      case SelectionEventType.selectParagraph:
        _start = Offset.zero;
        _end = Offset.infinite;
      case SelectionEventType.granularlyExtendSelection:
        final GranularlyExtendSelectionEvent extend =
            event as GranularlyExtendSelectionEvent;
        result = _extend(extend.forward, extend.isEnd);
      case SelectionEventType.directionallyExtendSelection:
        final DirectionallyExtendSelectionEvent extend =
            event as DirectionallyExtendSelectionEvent;
        final bool forward = switch (extend.direction) {
          SelectionExtendDirection.forward ||
          SelectionExtendDirection.nextLine => true,
          SelectionExtendDirection.backward ||
          SelectionExtendDirection.previousLine => false,
        };
        result = _extend(forward, extend.isEnd);
    }
    _updateGeometry();
    return result;
  }

  /// Moves one selection edge over the whole formula, since it can't be
  /// partly selected.
  SelectionResult _extend(bool forward, bool isEnd) {
    if (_start == null || _end == null) {
      _start = _end = forward ? Offset.zero : Offset.infinite;
    }
    final Offset edge = forward ? Offset.infinite : Offset.zero;
    final bool atEdge = isEnd ? _end == edge : _start == edge;
    if (isEnd) {
      _end = edge;
    } else {
      _start = edge;
    }
    if (!atEdge) return SelectionResult.end;
    return forward ? SelectionResult.next : SelectionResult.previous;
  }

  @override
  SelectedContent? getSelectedContent() =>
      value.hasSelection ? SelectedContent(plainText: text) : null;

  @override
  SelectedContentRange? getSelection() => value.hasSelection
      ? SelectedContentRange(startOffset: 0, endOffset: contentLength)
      : null;

  @override
  int get contentLength => 1;

  LayerLink? _startHandle;
  LayerLink? _endHandle;

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (_startHandle == startHandle && _endHandle == endHandle) return;
    _startHandle = startHandle;
    _endHandle = endHandle;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!value.hasSelection) return;
    context.canvas.drawRect(
      _bounds.shift(offset),
      Paint()..color = _selectionColor,
    );
    if (_startHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandle!,
          offset: offset + value.startSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
    if (_endHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandle!,
          offset: offset + value.endSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
  }

  @override
  void dispose() {
    _geometry.dispose();
    _startHandle = _endHandle = null;
    super.dispose();
  }
}
