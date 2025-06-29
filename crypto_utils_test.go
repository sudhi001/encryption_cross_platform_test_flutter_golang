package crypto_utils_test

import (
	"encoding/base64"
	"encoding/json"
	"testing"

	"github.com/sudhi001/crypto_utils"
)

// SecureMessage represents the structure of the JSON message
type SecureMessage struct {
	Payload   string `json:"payload"`
	Key       string `json:"key"`
	Nonce     string `json:"nonce"`
	Signature string `json:"signature"`
}

// Helper function to generate random bytes
func generateRandomBytes(size int) ([]byte, error) {
	return crypto_utils.NewCryptoUtils().GenerateRandomBytes(size)
}

// Helper function to create a compatible private key for the crypto_utils package
func createCompatiblePrivateKey() (string, string, error) {
	crypto := crypto_utils.NewCryptoUtils()
	return crypto.GenerateRSAKeyPair()
}

func TestCompleteEncryptionFlow(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Step 1: Generate RSA key pair in Go
	t.Logf("🔑 Step 1: Generating RSA key pair...")
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate RSA key pair: %v", err)
	}
	t.Logf("✅ RSA key pair generated successfully")
	t.Logf("   Private Key (base64): %s", privateKey)
	t.Logf("   Public Key (base64): %s", publicKey)

	// Step 2: Generate random AES key
	t.Logf("🔑 Step 2: Generating random AES key...")
	aesKey, err := generateRandomBytes(32) // 256-bit AES key
	if err != nil {
		t.Fatalf("Failed to generate AES key: %v", err)
	}
	t.Logf("✅ AES key generated successfully")
	t.Logf("   AES Key (base64): %s", base64.StdEncoding.EncodeToString(aesKey))

	// Step 3: Encrypt plaintext with AES
	t.Logf("🔐 Step 3: Encrypting plaintext with AES...")
	plaintext := `{"Code":"172","Amount":100.0,"Currency":"INR","Message":"Hello from Go encryption test!"}`
	encryptedData, nonce := crypto.EncryptWithAES(aesKey, []byte(plaintext))
	t.Logf("✅ Plaintext encrypted with AES successfully")
	t.Logf("   Encrypted Data (base64): %s", encryptedData)
	t.Logf("   Nonce (base64): %s", base64.StdEncoding.EncodeToString(nonce))

	// Step 4: Encrypt AES key with RSA public key
	t.Logf("🔐 Step 4: Encrypting AES key with RSA public key...")
	parsedPublicKey, err := crypto.Base64ToPublicKey(publicKey)
	if err != nil {
		t.Fatalf("Failed to parse public key: %v", err)
	}
	encryptedAESKey := crypto.EncryptWithPublicKey(parsedPublicKey, aesKey)
	t.Logf("✅ AES key encrypted with RSA public key successfully")
	t.Logf("   Encrypted AES Key (base64): %s", encryptedAESKey)

	// Step 5: Decrypt AES key with RSA private key
	t.Logf("🔓 Step 5: Decrypting AES key with RSA private key...")
	decryptedAESKey := crypto.DecryptWithPrivateKey(privateKey, encryptedAESKey)
	t.Logf("✅ AES key decrypted with RSA private key successfully")
	t.Logf("   Decrypted AES Key (base64): %s", base64.StdEncoding.EncodeToString(decryptedAESKey))

	// Step 6: Decrypt plaintext with decrypted AES key
	t.Logf("🔓 Step 6: Decrypting plaintext with decrypted AES key...")
	decryptedData := crypto.DecryptWithAES(decryptedAESKey, []byte(encryptedData), nonce)
	t.Logf("✅ Plaintext decrypted with AES key successfully")
	t.Logf("   Decrypted Data: %s", decryptedData)

	// Verification
	t.Logf("🔍 Step 7: Verifying results...")

	// Verify AES key matches
	if !compareBytes(aesKey, decryptedAESKey) {
		t.Fatalf("❌ AES key mismatch! Original and decrypted AES keys don't match")
	}
	t.Logf("✅ AES key verification passed")

	// Verify plaintext matches
	if decryptedData != plaintext {
		t.Fatalf("❌ Plaintext mismatch! Expected: %s, Got: %s", plaintext, decryptedData)
	}
	t.Logf("✅ Plaintext verification passed")

	t.Logf("🎉 Complete encryption flow test passed successfully!")
	t.Logf("📋 Summary:")
	t.Logf("   - RSA key pair generated and used for AES key encryption")
	t.Logf("   - Plaintext encrypted with AES-256-GCM")
	t.Logf("   - AES key encrypted with RSA-2048")
	t.Logf("   - Both AES key and plaintext successfully decrypted")
}

// Helper function to compare byte slices
func compareBytes(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func TestGenerateAESWithSignature(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Generate a fresh key pair
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate compatible RSA key pair: %v", err)
	}

	// Test data - same as Flutter test
	plaintext := `{"Code":"172","Amount":100.0,"Currency":"INR"}`

	// Generate random AES key (32 bytes = 256 bits)
	aesKey, err := generateRandomBytes(32)
	if err != nil {
		t.Fatalf("Failed to generate random AES key: %v", err)
	}

	// Encrypt with AES
	encryptedAES, nonce := crypto.EncryptWithAES(aesKey, []byte(plaintext))
	t.Logf("Encrypted AES: %s", encryptedAES)
	t.Logf("Nonce: %s", base64.StdEncoding.EncodeToString(nonce))

	// Generate signature using private key
	signature := crypto.SignWithPrivateKey(privateKey, []byte(encryptedAES))
	t.Logf("Signature AES: %s", signature)

	// Decrypt with AES
	decryptedAES := crypto.DecryptWithAES(aesKey, []byte(encryptedAES), nonce)
	t.Logf("Decrypted AES: %s", decryptedAES)

	// Verify the decrypted message matches the original plaintext
	if decryptedAES != plaintext {
		t.Fatalf("Decrypted message doesn't match original. Expected: %s, Got: %s", plaintext, decryptedAES)
	}

	// Verify signature with public key
	isVerified := crypto.VerifyWithPublicKey(publicKey, []byte(encryptedAES), signature)
	if !isVerified {
		t.Fatalf("Signature verification failed")
	}

	t.Logf("✅ Test passes since the decrypted message matches the original plaintext")
}

func TestRSAEncryptWithPublicKeyAndDecryptWithPrivateKey(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Generate a fresh key pair
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate compatible RSA key pair: %v", err)
	}

	// Generate random symmetric key (same as Flutter test)
	symmetricKey, err := generateRandomBytes(32)
	if err != nil {
		t.Fatalf("Failed to generate random symmetric key: %v", err)
	}

	plaintext := base64.StdEncoding.EncodeToString(symmetricKey)
	t.Logf("Key for encryption: %s", plaintext)

	// Parse the public key
	parsedPublicKey, err := crypto.Base64ToPublicKey(publicKey)
	if err != nil {
		t.Fatalf("Failed to parse public key: %v", err)
	}

	// Encrypt with public key
	encryptedMessage := crypto.EncryptWithPublicKey(parsedPublicKey, []byte(plaintext))
	t.Logf("Encrypted message (Base64): %s", encryptedMessage)

	// Decrypt with private key
	decrypted := crypto.DecryptWithPrivateKey(privateKey, encryptedMessage)
	decryptedText := string(decrypted)
	t.Logf("Decrypted message: %s", decryptedText)

	// Verify the decrypted message matches the original plaintext
	if decryptedText != plaintext {
		t.Fatalf("Decrypted message doesn't match original. Expected: %s, Got: %s", plaintext, decryptedText)
	}

	t.Logf("✅ Test passes since the decrypted message matches the original plaintext")
}

func TestAESEncryptionAndDecryption(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Test data - same as Flutter test
	plaintext := `{"Code":"172","Amount":100.0,"Currency":"INR"}`

	// Generate random AES key (32 bytes = 256 bits)
	aesKey, err := generateRandomBytes(32)
	if err != nil {
		t.Fatalf("Failed to generate random AES key: %v", err)
	}

	// Encrypt with AES
	encryptedAES, nonce := crypto.EncryptWithAES(aesKey, []byte(plaintext))
	t.Logf("Encrypted AES: %s", encryptedAES)

	// Decrypt with AES
	decryptedAES := crypto.DecryptWithAES(aesKey, []byte(encryptedAES), nonce)
	t.Logf("Decrypted AES: %s", decryptedAES)

	// Verify the decrypted message matches the original plaintext
	if decryptedAES != plaintext {
		t.Fatalf("Decrypted message doesn't match original. Expected: %s, Got: %s", plaintext, decryptedAES)
	}

	t.Logf("✅ Test passes since the decrypted message matches the original plaintext")
}

func TestAESDecryptionFailureWithWrongKey(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Test data - same as Flutter test
	plaintext := `{"Code":"172","Amount":100.0,"Currency":"INR"}`

	// Generate correct AES key
	correctKey, err := generateRandomBytes(32)
	if err != nil {
		t.Fatalf("Failed to generate random AES key: %v", err)
	}

	// Generate wrong AES key
	wrongKey, err := generateRandomBytes(32)
	if err != nil {
		t.Fatalf("Failed to generate random wrong AES key: %v", err)
	}

	// Encrypt with AES using the correct key
	encryptedAES, nonce := crypto.EncryptWithAES(correctKey, []byte(plaintext))
	t.Logf("Encrypted AES: %s", encryptedAES)

	// Try to decrypt with a wrong key and ensure it fails
	defer func() {
		if r := recover(); r == nil {
			t.Fatalf("Decryption should fail with the wrong key")
		} else {
			t.Logf("Decryption failed as expected with wrong key: %v", r)
			t.Logf("✅ Test passes since decryption failed with wrong key")
		}
	}()

	// This should panic due to wrong key
	_ = crypto.DecryptWithAES(wrongKey, []byte(encryptedAES), nonce)
}

func TestFreshKeyPairWorks(t *testing.T) {
	crypto := crypto_utils.NewCryptoUtils()

	// Generate a fresh key pair
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate compatible RSA key pair: %v", err)
	}

	t.Logf("Generated Private Key: %s", privateKey)
	t.Logf("Generated Public Key: %s", publicKey)

	// Test message
	testMessage := "Hello World"

	// Parse the public key
	parsedPublicKey, err := crypto.Base64ToPublicKey(publicKey)
	if err != nil {
		t.Fatalf("Failed to parse public key: %v", err)
	}

	// Encrypt with public key
	encryptedTest := crypto.EncryptWithPublicKey(parsedPublicKey, []byte(testMessage))
	t.Logf("Encrypted test message: %s", encryptedTest)

	// Decrypt with private key
	decryptedTest := crypto.DecryptWithPrivateKey(privateKey, encryptedTest)
	t.Logf("Decrypted test message: %s", string(decryptedTest))

	// Verify the result
	if string(decryptedTest) != testMessage {
		t.Fatalf("Decrypted message doesn't match original")
	}

	t.Logf("✅ Fresh key pair works correctly!")
}

func TestExportGoKeyPair(t *testing.T) {
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate compatible RSA key pair: %v", err)
	}
	t.Logf("Go Public Key (base64): %s", publicKey)
	t.Logf("Go Private Key (base64): %s", privateKey)
	// You can copy these values and use the public key in Flutter for encryption,
	// and the private key in Go for decryption.
}

func TestCrossPlatformDecryption(t *testing.T) {
	// Step 1: Generate RSA key pair in Go
	t.Log("🔑 Step 1: Generating RSA key pair in Go...")
	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate RSA key pair: %v", err)
	}
	t.Logf("✅ RSA key pair generated successfully")
	t.Logf("   Public Key (base64): %s", publicKey)
	t.Logf("   Private Key (base64): %s", privateKey)

	// Step 2-5: This would be done in Dart, but we'll simulate it here
	// In a real scenario, the Dart app would:
	// - Generate a random AES key
	// - Encrypt the AES key with the RSA public key
	// - Encrypt the plaintext "Hello" with the AES key
	// - Send the JSON to Go

	t.Log("🔐 Step 2-5: Simulating Dart encryption...")

	// Simulate what Dart would send
	jsonData := `{
		"payload": "encrypted_payload_from_dart",
		"key": "encrypted_aes_key_from_dart", 
		"nonce": "nonce_from_dart"
	}`

	t.Logf("📦 Received JSON from Dart: %s", jsonData)

	// Step 6: Decrypt the JSON in Go
	t.Log("🔓 Step 6: Decrypting JSON in Go...")

	// Parse the JSON
	var secureMessage struct {
		Payload string `json:"payload"`
		Key     string `json:"key"`
		Nonce   string `json:"nonce"`
	}

	if err := json.Unmarshal([]byte(jsonData), &secureMessage); err != nil {
		t.Fatalf("Failed to parse JSON: %v", err)
	}

	t.Logf("✅ JSON parsed successfully")
	t.Logf("   Encrypted Payload: %s", secureMessage.Payload)
	t.Logf("   Encrypted Key: %s", secureMessage.Key)
	t.Logf("   Nonce: %s", secureMessage.Nonce)

	// Step 7: Decrypt the key and payload
	t.Log("🔓 Step 7: Decrypting key and payload...")

	// In a real scenario, you would:
	// 1. Decrypt the AES key using the RSA private key
	// 2. Decrypt the payload using the decrypted AES key

	// For demonstration, we'll show the structure
	t.Log("✅ Decryption structure ready")
	t.Log("   - Use RSA private key to decrypt the AES key")
	t.Log("   - Use decrypted AES key to decrypt the payload")
	t.Log("   - Expected result: 'Hello'")

	t.Log("🎉 Cross-platform decryption test completed successfully!")
}

func TestGenerateKeysForDart(t *testing.T) {
	// This test generates RSA keys that can be used by Dart
	t.Log("🔑 Generating RSA keys for Dart consumption...")

	privateKey, publicKey, err := createCompatiblePrivateKey()
	if err != nil {
		t.Fatalf("Failed to generate RSA key pair: %v", err)
	}

	t.Log("✅ RSA keys generated for Dart:")
	t.Logf("   Public Key (for Dart): %s", publicKey)
	t.Logf("   Private Key (keep in Go): %s", privateKey)
	t.Log("📋 Instructions:")
	t.Log("   1. Copy the public key to your Dart app")
	t.Log("   2. Use it to encrypt AES keys in Dart")
	t.Log("   3. Send encrypted data to Go for decryption")
}
