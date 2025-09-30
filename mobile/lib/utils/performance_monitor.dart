import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring utility for Flutter app
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _measurements = {};
  final List<PerformanceMetric> _metrics = [];

  /// Start timing an operation
  void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing an operation
  Duration endTiming(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) {
      debugPrint('PerformanceMonitor: No start time found for operation: $operation');
      return Duration.zero;
    }

    final duration = DateTime.now().difference(startTime);
    _measurements.putIfAbsent(operation, () => []).add(duration);
    
    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      debugPrint('🐌 Slow operation: $operation took ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Measure widget build time
  Duration measureWidgetBuild(String widgetName, VoidCallback buildFunction) {
    startTiming('widget_build_$widgetName');
    buildFunction();
    return endTiming('widget_build_$widgetName');
  }

  /// Measure API call duration
  Future<T> measureApiCall<T>(String endpoint, Future<T> Function() apiCall) async {
    startTiming('api_$endpoint');
    try {
      final result = await apiCall();
      endTiming('api_$endpoint');
      return result;
    } catch (error) {
      endTiming('api_$endpoint');
      rethrow;
    }
  }

  /// Get average duration for an operation
  Duration getAverageDuration(String operation) {
    final measurements = _measurements[operation];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }

    final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ measurements.length);
  }

  /// Get all performance metrics
  List<PerformanceMetric> getAllMetrics() {
    final metrics = <PerformanceMetric>[];
    
    _measurements.forEach((operation, durations) {
      final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      final averageMs = totalMs ~/ durations.length;
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);

      metrics.add(PerformanceMetric(
        operation: operation,
        count: durations.length,
        averageDuration: Duration(milliseconds: averageMs),
        maxDuration: Duration(milliseconds: maxMs),
        minDuration: Duration(milliseconds: minMs),
        totalDuration: Duration(milliseconds: totalMs),
      ));
    });

    return metrics;
  }

  /// Clear all measurements
  void clearMeasurements() {
    _startTimes.clear();
    _measurements.clear();
    _metrics.clear();
  }

  /// Get system information
  Map<String, dynamic> getSystemInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isDebug': kDebugMode,
      'isRelease': kReleaseMode,
      'isProfile': kProfileMode,
    };
  }

  /// Generate performance report
  String generateReport() {
    final metrics = getAllMetrics();
    final systemInfo = getSystemInfo();
    
    final buffer = StringBuffer();
    buffer.writeln('📊 Performance Report');
    buffer.writeln('====================');
    buffer.writeln('Platform: ${systemInfo['platform']}');
    buffer.writeln('Debug Mode: ${systemInfo['isDebug']}');
    buffer.writeln('');
    
    if (metrics.isEmpty) {
      buffer.writeln('No performance data available.');
      return buffer.toString();
    }

    // Sort by average duration (slowest first)
    metrics.sort((a, b) => b.averageDuration.compareTo(a.averageDuration));

    buffer.writeln('Operation Performance:');
    buffer.writeln('');
    
    for (final metric in metrics) {
      buffer.writeln('${metric.operation}:');
      buffer.writeln('  Count: ${metric.count}');
      buffer.writeln('  Average: ${metric.averageDuration.inMilliseconds}ms');
      buffer.writeln('  Min: ${metric.minDuration.inMilliseconds}ms');
      buffer.writeln('  Max: ${metric.maxDuration.inMilliseconds}ms');
      buffer.writeln('  Total: ${metric.totalDuration.inMilliseconds}ms');
      buffer.writeln('');
    }

    // Performance insights
    final slowOperations = metrics.where((m) => m.averageDuration.inMilliseconds > 1000).toList();
    if (slowOperations.isNotEmpty) {
      buffer.writeln('🐌 Slow Operations (>1s):');
      for (final operation in slowOperations) {
        buffer.writeln('  - ${operation.operation}: ${operation.averageDuration.inMilliseconds}ms');
      }
      buffer.writeln('');
    }

    final frequentOperations = metrics.where((m) => m.count > 10).toList();
    if (frequentOperations.isNotEmpty) {
      buffer.writeln('🔄 Frequent Operations (>10 calls):');
      for (final operation in frequentOperations) {
        buffer.writeln('  - ${operation.operation}: ${operation.count} calls');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operation;
  final int count;
  final Duration averageDuration;
  final Duration maxDuration;
  final Duration minDuration;
  final Duration totalDuration;

  PerformanceMetric({
    required this.operation,
    required this.count,
    required this.averageDuration,
    required this.maxDuration,
    required this.minDuration,
    required this.totalDuration,
  });
}

/// Performance monitoring widget
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitorWidget({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget>
    with WidgetsBindingObserver {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  Timer? _reportTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
      _startPeriodicReporting();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
      _reportTimer?.cancel();
    }
    super.dispose();
  }

  void _startPeriodicReporting() {
    _reportTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _logPerformanceReport();
      }
    });
  }

  void _logPerformanceReport() {
    final report = _monitor.generateReport();
    debugPrint(report);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _logPerformanceReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Performance monitoring mixin for widgets
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void initState() {
    super.initState();
    _monitor.startTiming('widget_init_${T.toString()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor.endTiming('widget_init_${T.toString()}');
    _monitor.startTiming('widget_build_${T.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    _monitor.endTiming('widget_build_${T.toString()}');
    return buildWithMonitoring(context);
  }

  Widget buildWithMonitoring(BuildContext context);
}

/// Performance monitoring extension for Future
extension PerformanceMonitoringFuture<T> on Future<T> {
  Future<T> measurePerformance(String operation) async {
    return PerformanceMonitor().measureApiCall(operation, () => this);
  }
}

