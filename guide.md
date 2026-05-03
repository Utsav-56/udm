TASK TYPE:
Technical Documentation Generation - Dart Docstrings

INSTRUCTIONS:
You are an expert Dart developer. Your task is to write high-quality, deeply explanatory docstrings for every entity in the provided Dart code (classes, methods, fields, getters, parameters, and libraries).

1. Analyze the provided Dart code to understand its purpose, functionality, parameters, return types, and side effects.
2. Generate a docstring for each entity following official Dart documentation best practices.
3. Ensure the documentation is exhaustive so that a developer can understand everything about the entity without needing to assume anything or read the underlying code.
4. Format all docstrings using Dart's `///` syntax.

DO:
- Use clear, professional, and deeply explanatory language.
- Explain what the entity does, how it does it, its limitations, and its dependencies/needs.
- For methods/functions: Document all parameters, expected return types, side effects, what it may throw, and when to use it.
- For fields/getters: Explain their purpose, limitations, and edge cases (e.g., when they can be null).
- For libraries: Explain what the library includes, its purpose, how it works, copyright info, and provide usage examples.
- Use square brackets `[ComponentName]` to reference other code elements within the docstring.

DON'T:
- Don't write generic, brief, or uninformative summaries.
- Don't leave any parameter, return type, or exception undocumented for methods.
- Don't assume the reader knows the internal implementation details.
- Don't use `//` for docstrings; always use `///`.

EXAMPLES:
Example 1 - Class Docstring:
/// An isolated Dart execution context.
///
/// All Dart code runs in an isolate, and code can access classes and values
/// only from the same isolate. Different isolates can communicate by sending
/// values through ports (see [ReceivePort], [SendPort]).
///
/// An `Isolate` object is a reference to an isolate, usually different from
/// the current isolate.
/// It represents, and can be used to control, the other isolate.
///
/// When spawning a new isolate, the spawning isolate receives an `Isolate`
/// object representing the new isolate when the spawn operation succeeds.
///
/// Isolates run code in its own event loop, and each event may run smaller tasks
/// in a nested microtask queue.
///
/// An `Isolate` object allows other isolates to control the event loop
/// of the isolate that it represents, and to inspect the isolate,
/// for example by pausing the isolate or by getting events when the isolate
/// has an uncaught error.
///
/// The [controlPort] identifies and gives access to controlling the isolate,
/// and the [pauseCapability] and [terminateCapability] guard access
/// to some control operations.
/// For example, calling [pause] on an `Isolate` object created without a
/// [pauseCapability], has no effect.
///
/// The `Isolate` object provided by a spawn operation will have the
/// control port and capabilities needed to control the isolate.
/// New isolate objects can be created without some of these capabilities
/// if necessary, using the [Isolate.new] constructor.
///
/// An `Isolate` object cannot be sent over a `SendPort`, but the control port
/// and capabilities can be sent, and can be used to create a new functioning
/// `Isolate` object in the receiving port's isolate.

Example 2 - Method Docstring:
  /// Creates the file.
  ///
  /// Returns a `Future<File>` that completes with
  /// the file when it has been created.
  ///
  /// If [recursive] is `false`, the default, the file is created only if
  /// all directories in its path already exist. If [recursive] is `true`, any
  /// non-existing parent paths are created first.
  ///
  /// If [exclusive] is `true` and to-be-created file already exists, this
  /// operation completes the future with a [PathExistsException].
  ///
  /// If [exclusive] is `false`, existing files are left untouched by [create].
  /// Calling [create] on an existing file still might fail if there are
  /// restrictive permissions on the file.
  ///
  /// Completes the future with a [FileSystemException] if the operation fails.
  Future<File> create({bool recursive = false, bool exclusive = false});

Example 3 - Field/Getter Docstring:
  /// The file system path on which the error occurred.
  ///
  /// Can be `null` if the exception does not relate directly
  /// to a file system path.
  final String? path;

Example 4 - Library Docstring:
/// File, socket, HTTP, and other I/O support for non-web applications.
///
/// **Important:** Browser-based apps can't use this library.
/// Only the following can import and use the dart:io library:
///   - Servers
///   - Command-line scripts
///   - Flutter mobile apps
///   - Flutter desktop apps
///
/// This library allows you to work with files, directories,
/// sockets, processes, HTTP servers and clients, and more.
/// Many operations related to input and output are asynchronous
/// and are handled using [Future]s or [Stream]s, both of which
/// are defined in the [dart:async
/// library](../dart-async/dart-async-library.html).
///
/// To use the dart:io library in your code:
/// ```dart
/// import 'dart:io';
/// ```

CONTEXT:
[Insert the Dart code that needs to be documented here]
