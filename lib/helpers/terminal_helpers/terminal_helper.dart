import 'dart:io';

enum TerminalColor {
  red("\x1B[31m"),
  green("\x1B[32m"),
  yellow("\x1B[33m"),
  blue("\x1B[34m"),
  cyan("\x1B[36m"),
  reset("\x1B[0m");

  final String colorCode;

  const TerminalColor(this.colorCode);
}

/// Useful direct constants for short redable code
/// Tc stands for terminal color
final String yellowTc = TerminalColor.yellow.colorCode;
final String redTc = TerminalColor.red.colorCode;
final String greenTc = TerminalColor.green.colorCode;
final String blueTc = TerminalColor.blue.colorCode;
final String cyanTc = TerminalColor.cyan.colorCode;
final String resetTc = TerminalColor.reset.colorCode;

class TerminalHelper {
  static String _makeMessage(
    String message,
    TerminalColor terminalColor, {
    String? label,
  }) {
    if (label != null) {
      return "[ ${terminalColor.colorCode} $label $resetTc ] $message$resetTc";
    } else {
      return "${terminalColor.colorCode} $message$resetTc";
    }
  }

  static void logError(String message, [String? label]) {
    stderr.writeln(_makeMessage(message, TerminalColor.red, label: label));
  }

  static void logInfo(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.blue, label: label));
  }

  static void logSuccess(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.green, label: label));
  }

  static void logWarning(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.yellow, label: label));
  }

  /// Clears the terminal screen and moves the cursor to the top-left corner.
  static void clearScreen() {
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  static void enableRawMode() {
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
      stdin.echoNewlineMode = false;
    }
  }

  static void disableRawMode() {
    if (stdin.hasTerminal) {
      stdin.echoMode = true;
      stdin.lineMode = true;
      stdin.echoNewlineMode = true;
    }
  }
}

/// prints a message and cleans the next n lines in terminal
void println(String message, [int linesToClean = 1]) {
  cleanln(linesToClean);
  stdout.writeln("$message");
}

/// cleans last n lines in terminal
void cleanln(int n) {
  for (int i = 0; i < n; i++) {
    stdout.write('\x1B[1A'); // Move cursor up one line
    stdout.write('\x1B[2K'); // Clear the entire line
  }
}
