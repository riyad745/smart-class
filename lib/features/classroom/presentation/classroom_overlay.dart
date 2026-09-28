import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/classroom_tools_provider.dart';

/// Wraps a teaching screen and layers the classroom tools on top:
/// spotlight, a draggable timer/stopwatch, and an "exit zen mode" handle.
class ClassroomOverlay extends ConsumerStatefulWidget {
  const ClassroomOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ClassroomOverlay> createState() => _ClassroomOverlayState();
}

class _ClassroomOverlayState extends ConsumerState<ClassroomOverlay> {
  Offset? _pointer;
  Offset _timerPosition = const Offset(16, 80);

  @override
  Widget build(BuildContext context) {
    final tools = ref.watch(classroomToolsProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) => _track(e.localPosition, tools.spotlight),
      onPointerMove: (e) => _track(e.localPosition, tools.spotlight),
      onPointerDown: (e) => _track(e.localPosition, tools.spotlight),
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (tools.spotlight)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SpotlightPainter(_pointer)),
              ),
            ),
          if (tools.timerVisible)
            Positioned(
              left: _timerPosition.dx,
              top: _timerPosition.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _timerPosition += d.delta),
                child: ClassTimer(
                  onClose:
                      ref.read(classroomToolsProvider.notifier).toggleTimer,
                ),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Opacity(
              opacity: 0.5,
              child: IconButton.filledTonal(
                tooltip: tools.toolbarVisible ? 'Hide toolbar' : 'Show toolbar',
                icon: Icon(
                  tools.toolbarVisible ? Icons.expand_less : Icons.construction,
                ),
                onPressed:
                    ref.read(classroomToolsProvider.notifier).toggleToolbar,
              ),
            ),
          ),
          if (tools.zenMode)
            Positioned(
              right: 8,
              top: 8,
              child: Opacity(
                opacity: 0.35,
                child: IconButton.filledTonal(
                  tooltip: 'Exit zen mode',
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed:
                      ref.read(classroomToolsProvider.notifier).toggleZen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _track(Offset position, bool spotlight) {
    if (spotlight) setState(() => _pointer = position);
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.center);

  final Offset? center;

  @override
  void paint(Canvas canvas, Size size) {
    final c = center ?? size.center(Offset.zero);
    final radius = size.shortestSide * 0.18;
    final path =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(Rect.fromCircle(center: c, radius: radius));
    canvas.drawPath(path, Paint()..color = const Color(0xB3000000));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.center != center;
}

/// Countdown timer and stopwatch in one compact card.
class ClassTimer extends StatefulWidget {
  const ClassTimer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ClassTimer> createState() => _ClassTimerState();
}

class _ClassTimerState extends State<ClassTimer> {
  static const _presets = [1, 3, 5, 10, 15, 30];

  Timer? _ticker;
  bool _countdown = false;
  Duration _target = const Duration(minutes: 5);
  final Stopwatch _watch = Stopwatch();

  Duration get _shown {
    if (!_countdown) return _watch.elapsed;
    final left = _target - _watch.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get _finished => _countdown && _shown == Duration.zero;

  void _toggle() {
    setState(() {
      if (_watch.isRunning) {
        _watch.stop();
        _ticker?.cancel();
      } else {
        _watch.start();
        _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
          if (_finished) _watch.stop();
          setState(() {});
        });
      }
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(_watch.reset);
    _watch.stop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: _finished ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: false, label: Text('Stopwatch')),
                    ButtonSegment(value: true, label: Text('Timer')),
                  ],
                  selected: {_countdown},
                  onSelectionChanged: (s) {
                    _reset();
                    setState(() => _countdown = s.first);
                  },
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            Text(
              _format(_shown),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (_countdown &&
                !_watch.isRunning &&
                _watch.elapsed == Duration.zero)
              Wrap(
                spacing: 4,
                children: [
                  for (final m in _presets)
                    ChoiceChip(
                      label: Text('${m}m'),
                      selected: _target.inMinutes == m,
                      onSelected:
                          (_) => setState(() => _target = Duration(minutes: m)),
                    ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  tooltip: _watch.isRunning ? 'Pause' : 'Start',
                  icon: Icon(_watch.isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: _finished ? null : _toggle,
                ),
                IconButton(
                  tooltip: 'Reset',
                  icon: const Icon(Icons.replay),
                  onPressed: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
