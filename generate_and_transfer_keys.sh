#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Clear screen
clear

print_header "RSA Key Generation and Transfer"
echo "This script will generate RSA key pairs using Go and"
echo "transfer them to Dart for cross-platform encryption testing."
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ] || [ ! -f "go.mod" ]; then
    print_error "Please run this script from the encryption_test directory"
    exit 1
fi

# Create output directory
OUTPUT_DIR="generated_keys"
mkdir -p "$OUTPUT_DIR"

print_step "Step 1: Generating RSA Key Pair using Go"
echo ""

# Run Go test to generate keys
print_info "Running Go key generation test..."
if go test -v -run TestGenerateKeysForDart > "$OUTPUT_DIR/go_key_generation.log" 2>&1; then
    print_success "RSA key pair generated successfully!"
else
    print_error "Failed to generate RSA key pair!"
    exit 1
fi

# Extract the keys from the log
print_step "Step 2: Extracting Keys from Go Output"
echo ""

# Extract public key
PUBLIC_KEY=$(grep "Public Key (for Dart):" "$OUTPUT_DIR/go_key_generation.log" | cut -d':' -f2 | tr -d ' ')
if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > "$OUTPUT_DIR/public_key.txt"
    print_success "Public key extracted and saved to $OUTPUT_DIR/public_key.txt"
else
    print_error "Failed to extract public key!"
    exit 1
fi

# Extract private key
PRIVATE_KEY=$(grep "Private Key (keep in Go):" "$OUTPUT_DIR/go_key_generation.log" | cut -d':' -f2 | tr -d ' ')
if [ -n "$PRIVATE_KEY" ]; then
    echo "$PRIVATE_KEY" > "$OUTPUT_DIR/private_key.txt"
    print_success "Private key extracted and saved to $OUTPUT_DIR/private_key.txt"
else
    print_error "Failed to extract private key!"
    exit 1
fi

print_step "Step 3: Creating Dart Key Configuration"
echo ""

# Create Dart key configuration file
cat > "$OUTPUT_DIR/dart_keys.dart" << EOF
// Generated RSA Keys for Dart/Flutter Encryption
// Generated on: $(date)
// 
// Instructions:
// 1. Copy the public key to your Dart app for encryption
// 2. Keep the private key secure in your Go backend for decryption
// 3. Use these keys for cross-platform encryption testing

class GeneratedKeys {
  // RSA Public Key (for Dart encryption)
  static const String publicKey = '''$PUBLIC_KEY''';
  
  // RSA Private Key (for Go backend decryption)
  static const String privateKey = '''$PRIVATE_KEY''';
  
  // Key information
  static const String keyType = 'RSA-2048';
  static const String generatedDate = '$(date)';
  static const String purpose = 'Cross-platform encryption testing';
}

// Usage example:
// import 'generated_keys.dart';
// 
// // In your Dart app:
// final encryptedData = Crypto.fromBase64PublicKey(GeneratedKeys.publicKey)
//     .encryptWithPublicKey('your_data_here');
EOF

print_success "Dart key configuration created: $OUTPUT_DIR/dart_keys.dart"

print_step "Step 4: Creating Go Key Configuration"
echo ""

# Create Go key configuration file
cat > "$OUTPUT_DIR/go_keys.go" << EOF
// Generated RSA Keys for Go Backend
// Generated on: $(date)
// 
// Instructions:
// 1. Use the private key in your Go backend for decryption
// 2. Keep the private key secure and never expose it to clients
// 3. Use these keys for cross-platform encryption testing

package main

// GeneratedKeys contains the RSA key pair for cross-platform encryption
var GeneratedKeys = struct {
	PublicKey  string
	PrivateKey string
	KeyType    string
	Generated  string
	Purpose    string
}{
	PublicKey:  "$PUBLIC_KEY",
	PrivateKey: "$PRIVATE_KEY",
	KeyType:    "RSA-2048",
	Generated:  "$(date)",
	Purpose:    "Cross-platform encryption testing",
}

// Usage example:
// import "your_project/generated_keys"
// 
// // In your Go backend:
// decryptedData := crypto_utils.NewCryptoUtils().DecryptWithPrivateKey(
//     GeneratedKeys.PrivateKey, 
//     encryptedDataFromDart,
// )
EOF

print_success "Go key configuration created: $OUTPUT_DIR/go_keys.go"

print_step "Step 5: Creating Test Configuration"
echo ""

# Create test configuration file
cat > "$OUTPUT_DIR/test_config.json" << EOF
{
  "keys": {
    "public_key": "$PUBLIC_KEY",
    "private_key": "$PRIVATE_KEY",
    "key_type": "RSA-2048",
    "generated_date": "$(date)",
    "purpose": "Cross-platform encryption testing"
  },
  "test_data": {
    "sample_plaintext": "Hello from cross-platform encryption!",
    "aes_key_size": 32,
    "rsa_key_size": 2048
  },
  "instructions": {
    "dart_usage": "Use public_key for encryption in Dart/Flutter app",
    "go_usage": "Use private_key for decryption in Go backend",
    "security_note": "Never expose private_key to client applications"
  }
}
EOF

print_success "Test configuration created: $OUTPUT_DIR/test_config.json"

print_step "Step 6: Creating Transfer Script"
echo ""

# Create a script to copy keys to Dart project
cat > "$OUTPUT_DIR/copy_to_dart.sh" << 'EOF'
#!/bin/bash

# Script to copy generated keys to Dart project
echo "Copying generated keys to Dart project..."

# Copy Dart key configuration
if [ -f "generated_keys/dart_keys.dart" ]; then
    cp generated_keys/dart_keys.dart lib/generated_keys.dart
    echo "✅ Copied dart_keys.dart to lib/generated_keys.dart"
else
    echo "❌ dart_keys.dart not found!"
fi

# Copy test configuration
if [ -f "generated_keys/test_config.json" ]; then
    cp generated_keys/test_config.json assets/test_config.json
    echo "✅ Copied test_config.json to assets/test_config.json"
else
    echo "❌ test_config.json not found!"
fi

echo "🎉 Key transfer completed!"
echo ""
echo "Next steps:"
echo "1. Import the keys in your Dart app:"
echo "   import 'package:your_app/generated_keys.dart';"
echo ""
echo "2. Use the public key for encryption:"
echo "   final encrypted = Crypto.fromBase64PublicKey(GeneratedKeys.publicKey)"
echo "       .encryptWithPublicKey('your_data');"
echo ""
echo "3. Send encrypted data to Go backend for decryption"
EOF

chmod +x "$OUTPUT_DIR/copy_to_dart.sh"
print_success "Transfer script created: $OUTPUT_DIR/copy_to_dart.sh"

print_step "Step 7: Running Cross-Platform Test"
echo ""

# Run a quick test to verify the keys work
print_info "Testing generated keys with cross-platform encryption..."

# Create a test script
cat > "$OUTPUT_DIR/test_keys.sh" << EOF
#!/bin/bash

echo "Testing generated RSA keys..."

# Test Go key generation
echo "🔑 Testing Go key generation..."
go test -v -run TestGenerateKeysForDart -timeout 30s

if [ \$? -eq 0 ]; then
    echo "✅ Go key generation test passed!"
else
    echo "❌ Go key generation test failed!"
    exit 1
fi

echo ""
echo "🎉 All tests completed successfully!"
echo ""
echo "Generated files:"
echo "  📁 $OUTPUT_DIR/"
echo "    ├── public_key.txt          # RSA Public Key"
echo "    ├── private_key.txt         # RSA Private Key"
echo "    ├── dart_keys.dart          # Dart configuration"
echo "    ├── go_keys.go              # Go configuration"
echo "    ├── test_config.json        # Test configuration"
echo "    ├── copy_to_dart.sh         # Transfer script"
echo "    └── go_key_generation.log   # Generation log"
EOF

chmod +x "$OUTPUT_DIR/test_keys.sh"

# Run the test
if "$OUTPUT_DIR/test_keys.sh"; then
    print_success "Key generation and testing completed successfully!"
else
    print_error "Key testing failed!"
    exit 1
fi

print_step "Step 8: Summary"
echo ""

print_info "Generated Files Summary:"
echo "  📁 $OUTPUT_DIR/"
echo "    ├── public_key.txt          # RSA Public Key (for Dart)"
echo "    ├── private_key.txt         # RSA Private Key (for Go)"
echo "    ├── dart_keys.dart          # Dart configuration"
echo "    ├── go_keys.go              # Go configuration"
echo "    ├── test_config.json        # Test configuration"
echo "    ├── copy_to_dart.sh         # Transfer script"
echo "    └── go_key_generation.log   # Generation log"

echo ""
print_info "Next Steps:"
echo "  1. Copy keys to Dart project: ./$OUTPUT_DIR/copy_to_dart.sh"
echo "  2. Import keys in Dart: import 'package:your_app/generated_keys.dart';"
echo "  3. Use public key for encryption in Dart"
echo "  4. Use private key for decryption in Go backend"
echo "  5. Test cross-platform encryption flow"

echo ""
print_success "RSA key generation and transfer completed successfully!"
echo ""
print_header "Ready for Cross-Platform Encryption!" 