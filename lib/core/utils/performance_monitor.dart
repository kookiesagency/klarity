import 'package:flutter/foundation.dart';

/// Performance monitoring utility
/// Use this to track and log performance metrics during development
class PerformanceMonitor {
  PerformanceMonitor._();

  static final Map<String, DateTime> _timers = {};
  static final Map<String, int> _counters = {};

  /// Start a performance timer
  static void startTimer(String name) {
    _timers[name] = DateTime.now();
  }

  /// Stop a timer and log the duration
  static Duration? stopTimer(String name, {bool logResult = true}) {
    final startTime = _timers[name];
    if (startTime == null) {
      if (kDebugMode) {
        print('⚠️ Timer "$name" was never started');
      }
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _timers.remove(name);

    if (logResult && kDebugMode) {
      final emoji = _getDurationEmoji(duration);
      print('$emoji [$name] took ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Measure the time taken by an operation
  static Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    bool logResult = true,
    int? warnThresholdMs,
  }) async {
    startTimer(name);
    try {
      final result = await operation();
      final duration = stopTimer(name, logResult: logResult);

      // Warn if operation took too long
      if (duration != null && warnThresholdMs != null) {
        if (duration.inMilliseconds > warnThresholdMs) {
          if (kDebugMode) {
            print('⚠️ SLOW: [$name] took ${duration.inMilliseconds}ms (threshold: ${warnThresholdMs}ms)');
          }
        }
      }

      return result;
    } catch (e) {
      stopTimer(name, logResult: false);
      if (kDebugMode) {
        print('❌ [$name] failed: $e');
      }
      rethrow;
    }
  }

  /// Measure the time taken by a synchronous operation
  static T measureSync<T>(
    String name,
    T Function() operation, {
    bool logResult = true,
    int? warnThresholdMs,
  }) {
    final startTime = DateTime.now();
    try {
      final result = operation();
      final duration = DateTime.now().difference(startTime);

      if (logResult && kDebugMode) {
        final emoji = _getDurationEmoji(duration);
        print('$emoji [$name] took ${duration.inMilliseconds}ms');
      }

      // Warn if operation took too long
      if (warnThresholdMs != null && duration.inMilliseconds > warnThresholdMs) {
        if (kDebugMode) {
          print('⚠️ SLOW: [$name] took ${duration.inMilliseconds}ms (threshold: ${warnThresholdMs}ms)');
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [$name] failed: $e');
      }
      rethrow;
    }
  }

  /// Increment a counter
  static void incrementCounter(String name) {
    _counters[name] = (_counters[name] ?? 0) + 1;
  }

  /// Get counter value
  static int getCounter(String name) {
    return _counters[name] ?? 0;
  }

  /// Reset counter
  static void resetCounter(String name) {
    _counters.remove(name);
  }

  /// Log counter value
  static void logCounter(String name) {
    final count = getCounter(name);
    if (kDebugMode) {
      print('📊 [$name] count: $count');
    }
  }

  /// Log all counters
  static void logAllCounters() {
    if (kDebugMode) {
      print('\n📊 Performance Counters:');
      _counters.forEach((name, count) {
        print('  $name: $count');
      });
      print('');
    }
  }

  /// Clear all timers and counters
  static void reset() {
    _timers.clear();
    _counters.clear();
  }

  /// Get emoji based on duration
  static String _getDurationEmoji(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 50) return '⚡'; // Very fast
    if (ms < 200) return '✅'; // Good
    if (ms < 500) return '⏱️'; // Acceptable
    if (ms < 1000) return '⚠️'; // Slow
    return '🐌'; // Very slow
  }

  /// Performance benchmarks for key operations
  static const benchmarks = {
    'app_startup': 2000, // 2 seconds
    'transaction_load': 500, // 500ms
    'transaction_pagination': 300, // 300ms
    'budget_calculation': 100, // 100ms
    'analytics_load': 500, // 500ms
    'database_query': 200, // 200ms
  };

  /// Check if duration meets benchmark
  static bool meetsBenchmark(String operation, Duration duration) {
    final threshold = benchmarks[operation];
    if (threshold == null) return true;
    return duration.inMilliseconds <= threshold;
  }

  /// Log benchmark result
  static void logBenchmark(String operation, Duration duration) {
    final meets = meetsBenchmark(operation, duration);
    final threshold = benchmarks[operation];

    if (kDebugMode) {
      if (meets) {
        print('✅ BENCHMARK PASSED: [$operation] ${duration.inMilliseconds}ms (target: ${threshold}ms)');
      } else {
        print('❌ BENCHMARK FAILED: [$operation] ${duration.inMilliseconds}ms (target: ${threshold}ms)');
      }
    }
  }
}

/// Extension methods for easy performance monitoring
extension FuturePerformanceMonitor<T> on Future<T> {
  /// Monitor this future's execution time
  Future<T> monitored(String name, {bool logResult = true}) {
    return PerformanceMonitor.measure(name, () => this, logResult: logResult);
  }
}

/// Usage examples:
///
/// ```dart
/// // Measure async operation
/// final transactions = await PerformanceMonitor.measure(
///   'Load Transactions',
///   () => repository.getTransactions(profileId),
/// );
///
/// // Measure sync operation
/// final grouped = PerformanceMonitor.measureSync(
///   'Group Transactions',
///   () => _groupTransactions(transactions),
/// );
///
/// // With warning threshold
/// await PerformanceMonitor.measure(
///   'Database Query',
///   () => supabase.from('table').select(),
///   warnThresholdMs: 200,
/// );
///
/// // Using extension
/// final result = await repository.getTransactions(id).monitored('Get Transactions');
///
/// // Counters
/// PerformanceMonitor.incrementCounter('widget_rebuilds');
/// PerformanceMonitor.logCounter('widget_rebuilds');
///
/// // Benchmarks
/// final duration = await PerformanceMonitor.measure('transaction_load', operation);
/// PerformanceMonitor.logBenchmark('transaction_load', duration);
/// ```
