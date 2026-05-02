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

mixin TerminalHelper {
  String _makeMessage(String message, TerminalColor terminalColor, {String? label}) {
    if (label != null) {
      return "[ ${terminalColor.colorCode} $label $resetTc ] $message$resetTc";
    } else {
      return "${terminalColor.colorCode} $message$resetTc";
    }
  }

  void logError(String message, [String? label]) {
    stderr.writeln(_makeMessage(message, TerminalColor.red, label: label));
  }

  void logInfo(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.blue, label: label));
  }

  void logSuccess(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.green, label: label));
  }

  void logWarning(String message, [String? label]) {
    stdout.writeln(_makeMessage(message, TerminalColor.yellow, label: label));
  }

  /// Clears the terminal screen and moves the cursor to the top-left corner.
  void clearScreen() {
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  void enableRawMode() {
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
      stdin.echoNewlineMode = false;
    }
  }

  void disableRawMode() {
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

/// A class for managing log buffer in terminal
/// use [cleanLastLinesAndPrint] to clean last n lines and print the given text
/// this class is usefull for printing progress bars and other dynamic information
class LogBuffer with TerminalHelper {
  LogBuffer();

  int _lastLineCount = 0;
  int _currentLineCursor = 0; // Tracks the horizontal column (0 to Width-1)

  /// The heavy lifter: Handles text, literal newlines, and automatic wrapping
  void write(String text) {
    if (text.isEmpty) return;

    final columns = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      // 1. Handle Literal Newlines
      // If i > 0, it means we split on a '\n'
      if (i > 0) {
        _lastLineCount++;
        _currentLineCursor = 0;
      }

      // 2. Initialize Line Count
      // If this is the first write ever, we are on at least one physical line
      if (_lastLineCount == 0) _lastLineCount = 1;

      final segment = lines[i];
      if (segment.isNotEmpty) {
        // 3. Handle Automatic Terminal Wrapping
        int totalHorizontal = _currentLineCursor + segment.length;

        // (total - 1) / columns calculates how many times we crossed the "edge"
        // e.g., 80 chars on 80 cols = 0 wraps (still on line 1)
        // 81 chars on 80 cols = 1 wrap (now on line 2)
        int wraps = (totalHorizontal - 1) ~/ columns;

        _lastLineCount += wraps;
        _currentLineCursor = totalHorizontal % columns;
      }
    }

    stdout.write(text);
  }

  /// Bulletproof writeln simply wraps the write logic with a trailing newline
  void writeln(String text) {
    write('$text\n');
  }

  /// Redraws a block of text, accounting for wrapping within that block
  void cleanLastLinesAndPrint(String text) {
    clean();
    write(text);
  }

  /// Moves the cursor up and clears every physical line we've tracked
  void clean() {
    if (_lastLineCount == 0) return;

    for (int i = 0; i < _lastLineCount; i++) {
      // Move up only if we aren't already at the top of our block
      if (i > 0) {
        stdout.write('\x1B[1A');
      }
      stdout.write('\r\x1B[2K');
    }

    _lastLineCount = 0;
    _currentLineCursor = 0;
  }

  void writeInfo(String text, {String? label}) {
    writeln(_makeMessage(text, TerminalColor.blue, label: label));
  }

  void writeSuccess(String text, {String? label}) {
    writeln(_makeMessage(text, TerminalColor.green, label: label));
  }

  void writeError(String text, {String? label}) {
    writeln(_makeMessage(text, TerminalColor.red, label: label));
  }

  void writeWarning(String text, {String? label}) {
    writeln(_makeMessage(text, TerminalColor.yellow, label: label));
  }

  void cleanLastLines() {
    cleanln(_lastLineCount);
    _lastLineCount = 0;
  }

  void cleanln(int n) {
    for (int i = 0; i < n; i++) {
      stdout.write('\x1B[1A'); // Move cursor UP one line
      stdout.write('\r\x1B[2K'); // Move to start and CLEAR the line
    }
    _lastLineCount -= n;
  }
}
