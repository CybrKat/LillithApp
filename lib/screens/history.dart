/// LillithApp - review logged temperatures and period starts.
///
/// Shows a biphasic-style line chart of the recent skin-temperature series
/// (with period-start days marked) plus a scrollable list of every reading,
/// each removable. Reads from [HealthRepository]; edits write straight back to
/// the POD.

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/temperature_reading.dart';
import 'package:lillith_app/services/health_repository.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final _repo = HealthRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  Future<void> _confirmDelete(TemperatureReading r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reading?'),
        content: Text(
          'Remove the ${r.celsius.toStringAsFixed(2)} °C reading for '
          '${_fmtDate(r.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _repo.removeReading(r.date);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        if (_repo.isLoading && !_repo.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final readings = _repo.readings; // newest first
        final periodDays =
            _repo.periods.map((p) => p.startDate).toSet();

        if (readings.isEmpty) {
          return _EmptyState();
        }

        // Chart wants oldest → newest and only a recent window.
        final chronological = readings.reversed.toList();
        final windowed = chronological.length > 60
            ? chronological.sublist(chronological.length - 60)
            : chronological;

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperature trend',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last ${windowed.length} readings. Vertical markers show '
                      'logged period starts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _TempChartPainter(
                          readings: windowed,
                          periodDays: periodDays,
                          lineColor: Theme.of(context).colorScheme.primary,
                          markerColor: Theme.of(context).colorScheme.error,
                          gridColor: Theme.of(context)
                              .colorScheme
                              .outlineVariant,
                          textColor: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All readings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final r in readings)
              Card(
                child: ListTile(
                  leading: Icon(
                    periodDays.contains(r.date)
                        ? Icons.water_drop
                        : Icons.thermostat,
                    color: periodDays.contains(r.date)
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text('${r.celsius.toStringAsFixed(2)} °C'),
                  subtitle: Text('${_fmtDate(r.date)} · ${r.source.label}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(r),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TempChartPainter extends CustomPainter {
  _TempChartPainter({
    required this.readings, // oldest → newest
    required this.periodDays,
    required this.lineColor,
    required this.markerColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<TemperatureReading> readings;
  final Set<DateTime> periodDays;
  final Color lineColor;
  final Color markerColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    const leftPad = 40.0;
    const bottomPad = 4.0;
    const topPad = 8.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    final temps = readings.map((r) => r.celsius).toList();
    var minT = temps.reduce((a, b) => a < b ? a : b);
    var maxT = temps.reduce((a, b) => a > b ? a : b);
    if (maxT - minT < 0.5) {
      // Pad a flat-ish range so the line isn't a hairline on the axis.
      final mid = (maxT + minT) / 2;
      minT = mid - 0.25;
      maxT = mid + 0.25;
    }

    double xFor(int i) => readings.length == 1
        ? leftPad + chartW / 2
        : leftPad + chartW * i / (readings.length - 1);
    double yFor(double t) =>
        topPad + chartH * (1 - (t - minT) / (maxT - minT));

    // Horizontal grid lines + axis labels (min, mid, max).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.5, 1.0]) {
      final t = minT + (maxT - minT) * frac;
      final y = yFor(t);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _label(canvas, t.toStringAsFixed(1), Offset(0, y - 6));
    }

    // Period-start markers.
    final markerPaint = Paint()
      ..color = markerColor.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (var i = 0; i < readings.length; i++) {
      if (periodDays.contains(readings[i].date)) {
        final x = xFor(i);
        canvas.drawLine(
          Offset(x, topPad),
          Offset(x, topPad + chartH),
          markerPaint,
        );
      }
    }

    // The temperature line.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < readings.length; i++) {
      final p = Offset(xFor(i), yFor(readings[i].celsius));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Data point dots.
    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < readings.length; i++) {
      canvas.drawCircle(
        Offset(xFor(i), yFor(readings[i].celsius)),
        2.5,
        dotPaint,
      );
    }
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TempChartPainter old) =>
      old.readings != readings || old.periodDays != periodDays;
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No readings yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Log a skin temperature on the Log page to start building your '
              'trend.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
