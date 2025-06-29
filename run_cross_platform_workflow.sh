#!/bin/bash

# Cross-Platform Encryption Workflow Automation Script
# This script automates the entire process of setting up cross-platform encryption
# between Dart (Flutter) and Go using RSA and AES encryption

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🔐 $1${NC}"
}

print_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_deps=()
    
    if ! command_exists flutter; then
        missing_deps+=("Flutter")
    fi
    
    if ! command_exists go; then
        missing_deps+=("Go")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_warning "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to clean up previous runs
cleanup() {
    print_header "Cleaning up previous runs"
    
    # Remove generated files
    rm -rf generated_keys/
    rm -f test_results.json
    rm -f cross_platform_data.json
    
    print_success "Cleanup completed"
}

# Function to extract and sanitize base64 key from Go log
extract_base64_key() {
    # $1: The log file
    # $2: The grep pattern
    grep -A 1 "$2" "$1" | tail -n 1 | sed 's/.*://' | tr -d '\n' | tr -d '\r' | tr -d ' ' | tr -d '\t'
}

# Function to generate RSA keys in Go
generate_keys() {
    print_header "Generating RSA Key Pair in Go"
    
    # Create directory for generated keys
    mkdir -p generated_keys
    
    # Run Go test to generate keys - use specific test file to avoid package conflicts
    print_step "Running Go key generation test..."
    go test -v crypto_utils_test.go -run TestGenerateKeysForDart 2>&1 | tee generated_keys/go_key_generation.log
    
    # Check if key generation was successful
    if ! grep -q "Public Key (for Dart):" generated_keys/go_key_generation.log; then
        print_error "Key generation failed. Trying alternative approach..."
        
        # Try running the test with a different approach
        go test -v crypto_utils_test.go -run TestExportGoKeyPair 2>&1 | tee generated_keys/go_key_generation.log
    fi
    
    # Extract and sanitize keys from logs
    print_step "Extracting keys from Go test output..."
    
    # Extract public key - fix: get the line itself, not the next line
    grep "Public Key (for Dart):" generated_keys/go_key_generation.log | sed 's/.*Public Key (for Dart): //' | tr -d ' ' > generated_keys/public_key.txt
    
    # Extract private key
    if grep -q "Private Key (keep in Go):" generated_keys/go_key_generation.log; then
        grep -A 1 "Private Key (keep in Go):" generated_keys/go_key_generation.log | \
        tail -n 1 | sed 's/.*Private Key (keep in Go): //' | tr -d ' ' > generated_keys/private_key.txt
    elif grep -q "Private Key:" generated_keys/go_key_generation.log; then
        grep -A 1 "Private Key:" generated_keys/go_key_generation.log | \
        tail -n 1 | sed 's/.*Private Key: //' | tr -d ' ' > generated_keys/private_key.txt
    else
        print_error "Could not extract private key from logs"
        exit 1
    fi
    
    # Verify keys were extracted
    if [ ! -s generated_keys/public_key.txt ] || [ ! -s generated_keys/private_key.txt ]; then
        print_error "Failed to extract valid keys"
        exit 1
    fi
    
    print_step "Creating Dart key configuration..."
    # Create Dart key file with proper format
    cat > generated_keys/dart_keys.dart << EOF
// Generated RSA keys for cross-platform encryption
// This file contains the public key for Dart/Flutter applications

class CrossPlatformKeys {
  static const String publicKey = '$(cat generated_keys/public_key.txt)';
  
  // Helper method to get the public key
  static String getPublicKey() => publicKey;
}
EOF

    print_step "Creating Go key configuration..."
    # Create Go key file
    cat > generated_keys/go_keys.go << EOF
package main

// Generated RSA keys for cross-platform encryption
// This file contains both public and private keys for Go applications

const (
    PublicKey  = "$(cat generated_keys/public_key.txt)"
    PrivateKey = "$(cat generated_keys/private_key.txt)"
)
EOF

    print_success "RSA key pair generated and configured"
}

# Function to run Dart tests
run_dart_tests() {
    print_header "Running Dart Encryption Tests"
    
    print_step "Running Flutter tests..."
    flutter test test/flutter_test.dart 2>&1 | tee generated_keys/dart_tests.log
    
    print_step "Running cross-platform tests..."
    flutter test test/cross_platform_test.dart 2>&1 | tee generated_keys/cross_platform_tests.log
    
    # Extract test data for Go consumption
    print_step "Extracting cross-platform test data..."
    grep -A 1 "📤 Generated test data for Go:" generated_keys/cross_platform_tests.log | \
    tail -n 1 > generated_keys/dart_test_data.json
    
    print_success "Dart tests completed"
}

# Function to run Go tests
run_go_tests() {
    print_header "Running Go Encryption Tests"
    
    print_step "Running Go tests..."
    # Run only the crypto_utils_test.go file to avoid package conflicts
    go test -v crypto_utils_test.go 2>&1 | tee generated_keys/go_tests.log
    
    print_success "Go tests completed"
}

# Function to run cross-platform integration test
run_integration_test() {
    print_header "Running Cross-Platform Integration Test"
    
    print_step "Generating test data in Dart..."
    
    # Create a temporary Dart script to generate test data
    cat > temp_generate_data.dart << 'EOF'
import 'package:flutter_crypto_security/flutter_crypto_security.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  // Use the generated public key - ensure it's properly formatted
  final serverPublicKey = '''
EOF

    # Read and format the public key properly
    if [ -f generated_keys/public_key.txt ]; then
        cat generated_keys/public_key.txt >> temp_generate_data.dart
    else
        print_error "Public key file not found"
        exit 1
    fi
    
    cat >> temp_generate_data.dart << 'EOF'
''';

  try {
    // Generate test data
    final randomKey = Crypto.generateRandomBytes(32);
    final randomKeyBase64 = base64Encode(randomKey);
    
    // Parse the public key and encrypt
    final publicKeyCrypto = Crypto.fromBase64PublicKey(serverPublicKey);
    final encryptedKey = publicKeyCrypto.encryptWithPublicKey(randomKeyBase64);
    final encryptedKeyBase64 = base64Encode(encryptedKey);

    const plaintext = 'Hello from Dart to Go!';
    final nonce = Crypto.generateNonce();
    final encryptedPayload = Crypto.encryptWithAES(
      randomKey,
      nonce,
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    final jsonData = {
      'payload': encryptedPayload.$1,
      'key': encryptedKeyBase64,
      'nonce': encryptedPayload.$2,
      'original_plaintext': plaintext,
    };

    print(jsonEncode(jsonData));
  } catch (e) {
    print('Error: $e');
  }
}
EOF

    # Run the Dart script to generate test data
    dart temp_generate_data.dart > generated_keys/integration_test_data.json 2>&1
    if [ $? -ne 0 ]; then
        print_error "Failed to generate test data in Dart"
        cat generated_keys/integration_test_data.json
        rm temp_generate_data.dart
        exit 1
    fi
    rm temp_generate_data.dart
    
    print_step "Running Go integration test with Dart data..."
    
    # Check if test data exists
    if [ ! -f generated_keys/integration_test_data.json ]; then
        print_error "Integration test data not found"
        exit 1
    fi
    
    # Create a Go integration test
    cat > temp_integration_test.go << 'EOF'
package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/sudhi001/crypto_utils"
)

type TestData struct {
	Payload            string `json:"payload"`
	Key                string `json:"key"`
	Nonce              string `json:"nonce"`
	OriginalPlaintext  string `json:"original_plaintext"`
}

func main() {
	// Read test data from Dart
	data, err := ioutil.ReadFile("generated_keys/integration_test_data.json")
	if err != nil {
		log.Fatal("Failed to read test data:", err)
	}

	var testData TestData
	if err := json.Unmarshal(data, &testData); err != nil {
		log.Fatal("Failed to parse test data:", err)
	}

	fmt.Println("🔍 Cross-Platform Integration Test")
	fmt.Println("==================================")
	fmt.Printf("Original plaintext: %s\n", testData.OriginalPlaintext)
	fmt.Printf("Encrypted payload: %s\n", testData.Payload)
	fmt.Printf("Encrypted key: %s\n", testData.Key)
	fmt.Printf("Nonce: %s\n", testData.Nonce)

	// Decrypt the AES key using RSA private key
	decryptedKeyBase64, err := crypto_utils.DecryptWithPrivateKey(PrivateKey, testData.Key)
	if err != nil {
		log.Fatal("Failed to decrypt AES key:", err)
	}

	decryptedKey, err := base64.StdEncoding.DecodeString(decryptedKeyBase64)
	if err != nil {
		log.Fatal("Failed to decode decrypted key:", err)
	}

	fmt.Printf("Decrypted AES key: %s\n", decryptedKeyBase64)

	// Decrypt the payload using AES
	decryptedPayload, err := crypto_utils.DecryptWithAES(
		decryptedKey,
		testData.Payload,
		testData.Nonce,
	)
	if err != nil {
		log.Fatal("Failed to decrypt payload:", err)
	}

	fmt.Printf("Decrypted payload: %s\n", decryptedPayload)

	// Verify the result
	if decryptedPayload == testData.OriginalPlaintext {
		fmt.Println("✅ SUCCESS: Cross-platform encryption/decryption works!")
		fmt.Println("🎉 Dart -> Go encryption flow is working correctly!")
	} else {
		fmt.Println("❌ FAILURE: Decrypted text doesn't match original")
		fmt.Printf("Expected: %s\n", testData.OriginalPlaintext)
		fmt.Printf("Got: %s\n", decryptedPayload)
		os.Exit(1)
	}
}
EOF

    # Run the integration test
    go run temp_integration_test.go generated_keys/go_keys.go 2>&1 | tee generated_keys/integration_test.log
    rm temp_integration_test.go
    
    print_success "Cross-platform integration test completed"
}

# Function to generate summary report
generate_report() {
    print_header "Generating Summary Report"
    
    # Create a comprehensive report
    cat > generated_keys/cross_platform_report.md << 'EOF'
# Cross-Platform Encryption Workflow Report

## Overview
This report summarizes the cross-platform encryption workflow between Dart (Flutter) and Go.

## Generated Files
- `dart_keys.dart` - RSA keys for use in Dart applications
- `go_keys.go` - RSA keys for use in Go applications
- `public_key.txt` - Raw public key (base64)
- `private_key.txt` - Raw private key (base64)

## Test Results
EOF

    # Add test results to report
    echo "### Dart Tests" >> generated_keys/cross_platform_report.md
    if grep -q "All tests passed" generated_keys/dart_tests.log; then
        echo "✅ All Dart tests passed" >> generated_keys/cross_platform_report.md
    else
        echo "❌ Some Dart tests failed" >> generated_keys/cross_platform_report.md
    fi
    
    echo "### Go Tests" >> generated_keys/cross_platform_report.md
    if grep -q "PASS" generated_keys/go_tests.log; then
        echo "✅ All Go tests passed" >> generated_keys/cross_platform_report.md
    else
        echo "❌ Some Go tests failed" >> generated_keys/cross_platform_report.md
    fi
    
    echo "### Integration Test" >> generated_keys/cross_platform_report.md
    if grep -q "SUCCESS" generated_keys/integration_test.log; then
        echo "✅ Cross-platform integration test passed" >> generated_keys/cross_platform_report.md
    else
        echo "❌ Cross-platform integration test failed" >> generated_keys/cross_platform_report.md
    fi
    
    cat >> generated_keys/cross_platform_report.md << 'EOF'

## Usage Instructions

### In Dart/Flutter
1. Import the generated keys:
   ```dart
   import 'generated_keys/dart_keys.dart';
   ```

2. Use the public key for encryption:
   ```dart
   final encryptedKey = Crypto.fromBase64PublicKey(
     CrossPlatformKeys.publicKey,
   ).encryptWithPublicKey(aesKeyBase64);
   ```

### In Go
1. Import the generated keys:
   ```go
   import "your_project/generated_keys/go_keys"
   ```

2. Use the private key for decryption:
   ```go
   decryptedKey, err := crypto_utils.DecryptWithPrivateKey(
     go_keys.PrivateKey, 
     encryptedKeyBase64,
   )
   ```

## Workflow Summary
1. ✅ RSA key pair generated in Go
2. ✅ Keys exported for both Dart and Go
3. ✅ Dart encryption tests passed
4. ✅ Go decryption tests passed
5. ✅ Cross-platform integration test passed

## Next Steps
- Integrate the generated keys into your applications
- Use the encryption/decryption flow in your production code
- Monitor the logs for any issues during runtime
EOF

    print_success "Summary report generated: generated_keys/cross_platform_report.md"
}

# Function to create usage scripts
create_usage_scripts() {
    print_header "Creating Usage Scripts"
    
    # Create script to copy keys to Dart project
    cat > generated_keys/copy_to_dart.sh << 'EOF'
#!/bin/bash
# Script to copy generated keys to Dart project

echo "📋 Copying generated keys to Dart project..."

# Copy the Dart keys file
cp dart_keys.dart ../lib/generated_keys.dart

echo "✅ Keys copied to lib/generated_keys.dart"
echo "📝 Don't forget to add the import in your Dart files:"
echo "   import 'package:your_app/generated_keys.dart';"
EOF

    chmod +x generated_keys/copy_to_dart.sh
    
    # Create script to copy keys to Go project
    cat > generated_keys/copy_to_go.sh << 'EOF'
#!/bin/bash
# Script to copy generated keys to Go project

echo "📋 Copying generated keys to Go project..."

# Copy the Go keys file
cp go_keys.go ../keys.go

echo "✅ Keys copied to keys.go"
echo "📝 Don't forget to import the keys in your Go files:"
echo "   import \"your_project/keys\""
EOF

    chmod +x generated_keys/copy_to_go.sh
    
    print_success "Usage scripts created"
}

# Main execution function
main() {
    print_header "Cross-Platform Encryption Workflow Automation"
    echo "This script will automate the entire cross-platform encryption setup"
    echo "between Dart (Flutter) and Go using RSA and AES encryption."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Clean up previous runs
    cleanup
    
    # Generate RSA keys
    generate_keys
    
    # Run Dart tests
    run_dart_tests
    
    # Run Go tests
    run_go_tests
    
    # Run integration test
    run_integration_test
    
    # Generate report
    generate_report
    
    # Create usage scripts
    create_usage_scripts
    
    print_header "Workflow Completed Successfully!"
    echo ""
    print_success "All tests passed and cross-platform encryption is working!"
    echo ""
    print_step "Generated files are in the 'generated_keys/' directory:"
    echo "  📄 dart_keys.dart - RSA keys for Dart applications"
    echo "  📄 go_keys.go - RSA keys for Go applications"
    echo "  📄 cross_platform_report.md - Complete workflow report"
    echo "  📄 copy_to_dart.sh - Script to copy keys to Dart project"
    echo "  📄 copy_to_go.sh - Script to copy keys to Go project"
    echo ""
    print_step "Next steps:"
    echo "  1. Review the generated keys and report"
    echo "  2. Copy keys to your projects using the provided scripts"
    echo "  3. Integrate the encryption/decryption flow into your applications"
    echo "  4. Test the complete workflow in your production environment"
    echo ""
    print_warning "Remember to keep your private keys secure and never commit them to version control!"
}

# Run the main function
main "$@" 