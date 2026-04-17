extension DateTimeX on DateTime {
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

  String get formatted {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final m = minute.toString().padLeft(2, '0');

    return '$hour12:$m $period';
  }
}

extension NullableDateTimeX on DateTime? {
  String readableDifference(DateTime? other) {
    if (this == null || other == null) return "N/A";
    return this!.readableDifference(other);
  }

  String get formatted {
    if (this == null) return "N/A";
    return this!.formatted;
  }
}
