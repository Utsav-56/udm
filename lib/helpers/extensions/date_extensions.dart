// Author:: Utsav Pokhrel
// Contact:: utsavpokhrel100@gmail.com
// Github:: https://github.com/utsav-56
//
// Provided under the MIT License.

/// Utility extensions for [DateTime] and [Duration].
///
/// This library provides formatting methods to convert dates and durations
/// into human-readable strings, optimized for logs and UI displays.
library;

extension DateTimeX on DateTime {
  /// Returns a human-readable representation of the difference between [this] and [other].
  ///
  /// Automatically scales the output unit (ms, s, m, h, d) based on the magnitude
  /// of the difference.
  String readableDifference(DateTime other) {
    final diff = difference(other).abs();

    final ms = diff.inMilliseconds;
    final seconds = diff.inSeconds;
    final minutes = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;

    // < 1 second → show ms
    if (ms < 1000) {
      return '${ms}ms';
    }

    // < 1 minute → show seconds (+ leftover ms if small)
    if (seconds < 60) {
      final remMs = ms % 1000;
      if (remMs > 0) {
        return '${seconds}s ${remMs}ms';
      }
      return '${seconds}s';
    }

    // < 1 hour → show minutes + seconds
    if (minutes < 60) {
      final remSec = seconds % 60;
      return remSec > 0 ? '${minutes}m ${remSec}s' : '${minutes}m';
    }

    // < 1 day → show hours + minutes
    if (hours < 24) {
      final remMin = minutes % 60;
      return remMin > 0 ? '${hours}h ${remMin}m' : '${hours}h';
    }

    // >= 1 day → show days + hours
    final remHr = hours % 24;
    return remHr > 0 ? '${days}d ${remHr}h' : '${days}d';
  }

  /// Formats the time as a 12-hour string with AM/PM (e.g., "10:30 AM").
  String get formatted {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final m = minute.toString().padLeft(2, '0');

    return '$hour12:$m $period';
  }
}

extension NullableDateTimeX on DateTime? {
  /// Safe version of [readableDifference] that returns "N/A" if either date is null.
  String readableDifference(DateTime? other) {
    if (this == null || other == null) return "N/A";
    return this!.readableDifference(other);
  }

  /// Safe version of [formatted] that returns "N/A" if the date is null.
  String get formatted {
    if (this == null) return "N/A";
    return this!.formatted;
  }
}

extension DurationX on Duration {
  /// Formats the duration into a concise, human-readable string.
  ///
  /// Example outputs: "5s 200ms", "10m 30s", "1d 5h".
  String get readableFormat {
    final seconds = inSeconds;
    final minutes = inMinutes;
    final hours = inHours;
    final days = inDays;

    // < 1 second → show ms
    if (seconds < 1) {
      return '${inMilliseconds}ms';
    }

    // < 1 minute → show seconds (+ leftover ms if small)
    if (seconds < 60) {
      final remMs = inMilliseconds % 1000;
      if (remMs > 0) {
        return '${seconds}s ${remMs}ms';
      }
      return '${seconds}s';
    }

    // < 1 hour → show minutes + seconds
    if (minutes < 60) {
      final remSec = seconds % 60;
      return remSec > 0 ? '${minutes}m ${remSec}s' : '${minutes}m';
    }

    // < 1 day → show hours + minutes
    if (hours < 24) {
      final remMin = minutes % 60;
      return remMin > 0 ? '${hours}h ${remMin}m' : '${hours}h';
    }

    // >= 1 day → show days + hours
    final remHr = hours % 24;
    return remHr > 0 ? '${days}d ${remHr}h' : '${days}d';
  }
}

