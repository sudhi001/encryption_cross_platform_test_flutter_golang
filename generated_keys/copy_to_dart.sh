#!/bin/bash
# Script to copy generated keys to Dart project

echo "📋 Copying generated keys to Dart project..."

# Copy the Dart keys file
cp dart_keys.dart ../lib/generated_keys.dart

echo "✅ Keys copied to lib/generated_keys.dart"
echo "📝 Don't forget to add the import in your Dart files:"
echo "   import 'package:your_app/generated_keys.dart';"
