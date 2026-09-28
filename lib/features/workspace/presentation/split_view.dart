import 'package:flutter/material.dart';

/// Two panes with a draggable divider. Horizontal (side by side) on wide
/// screens, vertical (stacked) on narrow ones.
class SplitView extends StatefulWidget {
  const SplitView({
    super.key,
    required this.first,
    required this.second,
    this.initialRatio = 0.5,
    this.minRatio = 0.2,
  });

  final Widget first;
  final Widget second;
  final double initialRatio;
  final double minRatio;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _ratio = widget.initialRatio;
  static const _handle = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= constraints.maxHeight * 0.9;
        final total =
            (horizontal ? constraints.maxWidth : constraints.maxHeight) -
            _handle;
        final firstSize = total * _ratio;

        final divider = MouseRegion(
          cursor:
              horizontal
                  ? SystemMouseCursors.resizeColumn
                  : SystemMouseCursors.resizeRow,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate:
                (d) => setState(() {
                  final delta = horizontal ? d.delta.dx : d.delta.dy;
                  _ratio = (_ratio + delta / total).clamp(
                    widget.minRatio,
                    1 - widget.minRatio,
                  );
                }),
            onDoubleTap: () => setState(() => _ratio = 0.5),
            child: Container(
              width: horizontal ? _handle : null,
              height: horizontal ? null : _handle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Container(
                width: horizontal ? 4 : 36,
                height: horizontal ? 36 : 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );

        final children = [
          SizedBox(
            width: horizontal ? firstSize : null,
            height: horizontal ? null : firstSize,
            child: ClipRect(child: widget.first),
          ),
          divider,
          Expanded(child: ClipRect(child: widget.second)),
        ];
        return horizontal
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }
}
