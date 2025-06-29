import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_crypto_security/flutter_crypto_security.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:logger/logger.dart';

final logger = Logger();

void main() {
  group('Cross-Platform Encryption Test', () {
    test('Dart Encryption Flow for Go Decryption', () {
      try {
        // Step 1: RSA key pair generated in Go (we'll use a pre-generated one)
        // This would normally come from your Go backend
        const serverPublicKey =
            'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEzaUVuK2NaVStkWDRyT0h6QmhndQowQk9BUG5SeVpQbUttOVprRStnNTlod0h4WDladzFQN2dxaEE0NlNQR0NKeGMwTGlnNkI5dHZGTkRNbkx1SmJMCndjSmtKOHF1aVc5c1RYYlVFNGVhSnd1d3BIRDNHbXZ1cGZFSFF6NGpBRXgycFFuQ0dwdHNQdGZwbnIxRGhOeDMKNU56UGk3Qmhick41K3ROWXR1ODZVaEVROUJ2MTZoZ1BiT3dKMEd3Q0Q4WWMyODlMN294L0NCS1N3b0R4WEs5MQpubnpmaE8zbzlibERsT3hPR2MyMkhEQVMvQU4vVTZHa2tpaGZBcmFTd2l1K2dvRlV5L3dWWkJDZ1dvdEZjdnZuClJnT3FnT2JadUpBbmJPbHMvcVl3S1lqOXdKZlJVeStXMjYwdW1IdnNCU3Y3aENIOFlMT2NXenBqeUxqZjNMTWIKMVFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==';

        // Step 2: Generate Random Key in Dart
        logger.i('🔑 Step 2: Generating Random Key in Dart...');
        final randomKey = Crypto.generateRandomBytes(32); // 256-bit AES key
        final randomKeyBase64 = base64Encode(randomKey);
        logger.i('✅ Random key generated successfully');
        logger.d('   Random Key (base64): $randomKeyBase64');

        // Step 3: Encrypt the Random Key using RSA key in Dart
        logger.i('🔐 Step 3: Encrypting Random Key using RSA public key...');
        final encryptedKey = Crypto.fromBase64PublicKey(
          serverPublicKey,
        ).encryptWithPublicKey(randomKeyBase64);
        final encryptedKeyBase64 = base64Encode(encryptedKey);
        logger.i('✅ Random key encrypted with RSA successfully');
        logger.d('   Encrypted Key (base64): $encryptedKeyBase64');

        // Step 4: Encrypt the Plain text "Hello" using Random Key in Dart
        logger.i('🔐 Step 4: Encrypting plaintext "Hello" using Random Key...');
        const plaintext = 'Hello';
        final nonce = Crypto.generateNonce();
        final encryptedPayload = Crypto.encryptWithAES(
          randomKey,
          nonce,
          Uint8List.fromList(utf8.encode(plaintext)),
        );
        logger.i('✅ Plaintext encrypted with AES successfully');
        logger.d('   Encrypted Payload (base64): ${encryptedPayload.$1}');
        logger.d('   Nonce (base64): ${encryptedPayload.$2}');

        // Step 5: Build JSON with encrypted data
        logger.i('📦 Step 5: Building JSON with encrypted data...');
        final jsonData = {
          'payload': encryptedPayload.$1,
          'key': encryptedKeyBase64,
          'nonce': encryptedPayload.$2,
        };
        final jsonString = jsonEncode(jsonData);
        logger.i('✅ JSON built successfully');
        logger.d('   JSON Data: $jsonString');

        // Step 6 & 7: This would be done in Go, but we'll simulate the verification here
        logger.i('🔍 Step 6 & 7: Simulating Go decryption verification...');

        // Verify our encryption worked by decrypting locally
        final decryptedPayload = Crypto.decryptWithAES(
          randomKey,
          encryptedPayload.$1,
          encryptedPayload.$2,
        );
        logger.i('✅ Local decryption verification successful');
        logger.d('   Decrypted Payload: $decryptedPayload');

        // Verify the result
        expect(decryptedPayload, equals(plaintext));
        logger.i(
          '✅ Verification passed: decrypted payload matches original plaintext',
        );

        // Print the JSON for Go to consume
        logger.i('📋 JSON for Go consumption:');
        logger.i(jsonString);

        logger.i('🎉 Cross-platform encryption test completed successfully!');
        logger.i('📋 Summary:');
        logger.i('   - Random AES key generated in Dart');
        logger.i('   - AES key encrypted with RSA public key from Go');
        logger.i('   - Plaintext "Hello" encrypted with AES');
        logger.i('   - JSON payload created for Go decryption');
        logger.i('   - Ready for Go backend to decrypt and process');
      } catch (e) {
        logger.e('❌ Cross-platform encryption test failed: $e');
        rethrow;
      }
    });

    test('Generate Test Data for Go', () {
      // This test generates sample data that can be used in Go tests
      const serverPublicKey =
          'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEzaUVuK2NaVStkWDRyT0h6QmhndQowQk9BUG5SeVpQbUttOVprRStnNTlod0h4WDladzFQN2dxaEE0NlNQR0NKeGMwTGlnNkI5dHZGTkRNbkx1SmJMCndjSmtKOHF1aVc5c1RYYlVFNGVhSnd1d3BIRDNHbXZ1cGZFSFF6NGpBRXgycFFuQ0dwdHNQdGZwbnIxRGhOeDMKNU56UGk3Qmhick41K3ROWXR1ODZVaEVROUJ2MTZoZ1BiT3dKMEd3Q0Q4WWMyODlMN294L0NCS1N3b0R4WEs5MQpubnpmaE8zbzlibERsT3hPR2MyMkhEQVMvQU4vVTZHa2tpaGZBcmFTd2l1K2dvRlV5L3dWWkJDZ1dvdEZjdnZuClJnT3FnT2JadUpBbmJPbHMvcVl3S1lqOXdKZlJVeStXMjYwdW1IdnNCU3Y3aENIOFlMT2NXenBqeUxqZjNMTWIKMVFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==';

      final randomKey = Crypto.generateRandomBytes(32);
      final randomKeyBase64 = base64Encode(randomKey);
      final encryptedKey = Crypto.fromBase64PublicKey(
        serverPublicKey,
      ).encryptWithPublicKey(randomKeyBase64);
      final encryptedKeyBase64 = base64Encode(encryptedKey);

      const plaintext = 'Hello from Dart!';
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
      };

      logger.i('📤 Generated test data for Go:');
      logger.i(jsonEncode(jsonData));
    });
  });
}
