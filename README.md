# Cross-Platform Encryption Testing: Flutter/Dart ↔ Go

A comprehensive testing framework for cross-platform encryption between Flutter/Dart applications and Go backends using RSA and AES encryption.

## 🚀 Features

- **RSA Key Generation** in Go with cross-platform compatibility
- **AES Encryption/Decryption** in both Dart and Go
- **Digital Signatures** for message integrity
- **Cross-Platform JSON** data exchange
- **Automated Testing** scripts for both platforms

## 📋 Prerequisites

- **Go** 1.24+ installed
- **Flutter** 3.0+ installed
- **Git** for version control

## 🛠️ Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd encryption_test
   ```
2. **Install Go and Flutter dependencies**
   - For Go:
     ```bash
     go mod tidy
     ```
   - For Flutter:
     ```bash
     flutter pub get
     ```

## 🧪 Running the Cross-Platform Encryption Test

The main workflow script automates the entire cross-platform encryption setup and test process:

```bash
./run_cross_platform_workflow.sh
```

### What the Script Does
- Cleans up previous runs and generated files
- Generates a new RSA key pair in Go
- Extracts and formats keys for both Dart and Go
- Runs all Dart encryption tests
- Runs all Go encryption tests
- Runs cross-platform encryption tests (Dart → Go and Go → Dart)
- Generates a summary report and usage scripts

### Expected Output
- All tests should pass in both Dart and Go
- The script will print a summary and generate files in the `generated_keys/` directory:
  - `dart_keys.dart` — RSA keys for Dart
  - `go_keys.go` — RSA keys for Go
  - `cross_platform_report.md` — Workflow report
  - `copy_to_dart.sh` — Script to copy keys to Dart project
  - `copy_to_go.sh` — Script to copy keys to Go project

### Next Steps
1. Review the generated keys and report in `generated_keys/`
2. Use the provided scripts to copy keys to your Dart or Go projects
3. Integrate the encryption/decryption flow into your applications
4. Test the complete workflow in your production environment

⚠️ **Important:**
- Keep your private keys secure and never commit them to version control!

## 📂 Project Structure

```
.
├── run_cross_platform_workflow.sh   # Main workflow script
├── crypto_utils_test.go             # Go encryption tests
├── test/
│   ├── flutter_test.dart            # Dart encryption tests
│   └── cross_platform_test.dart     # Cross-platform Dart tests
├── generated_keys/                  # Output directory for keys and reports
│   ├── dart_keys.dart
│   ├── go_keys.go
│   ├── cross_platform_report.md
│   └── ...
└── ...
```

## 📝 Example: Running the Workflow

```bash
./run_cross_platform_workflow.sh
```

You should see output indicating:
- RSA key generation in Go
- Dart and Go tests passing
- Cross-platform encryption test completed successfully
- Summary and next steps

## 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📄 License
[MIT](LICENSE)

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review test logs in `generated_keys/` directory
3. Run individual test scripts for specific functionality
4. Create an issue with detailed error information

---

**Last Updated**: $(date)
**Test Status**: ✅ All tests passing
**Compatibility**: Flutter 3.0+, Go 1.24+
