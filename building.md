<!-- updated :: 2026-05-03 14:53:00 -->

# Building UDM from Source

This guide provides a simple, step-by-step walkthrough to get UDM running on your local machine, even if you are not a professional developer.

## Step 1: Install the Requirements
Before we begin, you need to have the **Dart SDK** installed.
1. Visit the [Dart SDK Installation Page](https://dart.dev/get-dart).
2. Download the version suitable for your operating system (Windows, macOS, or Linux).
3. Follow the installer instructions.
4. To verify it worked, open your terminal and type:
   ```bash
   dart --version
   ```

## Step 2: Download the UDM Source Code
You can download the code using **Git**.
1. Open your terminal.
2. Run the following command:
   ```bash
   git clone https://github.com/Utsav-56/udm.git
   ```
3. Move into the project folder:
   ```bash
   cd udm
   ```

## Step 3: Prepare the Project
We need to download the "dependencies" (helper libraries) that UDM uses.
Run this command inside the `udm` folder:
```bash
dart pub get
```

## Step 4: Run UDM
You can now run UDM directly using the Dart VM:
```bash
dart bin/udm.dart "https://example.com/file.zip"
```

## Step 5: (Optional) Compile to a Permanent Program
If you want to use UDM like a regular app (without typing `dart bin/...`), you can compile it into an "executable":
```bash
dart compile exe bin/udm.dart -o udm
```
Now you can run it simply by typing:
```bash
./udm "https://example.com/file.zip"
```

## Troubleshooting
- **Command not found**: Make sure Dart is added to your system's "PATH" variable during installation.
- **Permission Denied**: If you are on Linux/macOS, you might need to give the compiled file permission to run: `chmod +x udm`.
