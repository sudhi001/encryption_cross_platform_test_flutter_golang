#!/bin/bash
# Script to copy generated keys to Go project

echo "📋 Copying generated keys to Go project..."

# Copy the Go keys file
cp go_keys.go ../keys.go

echo "✅ Keys copied to keys.go"
echo "📝 Don't forget to import the keys in your Go files:"
echo "   import \"your_project/keys\""
