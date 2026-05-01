import 'dart:io';

class TerminalHelper {
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
