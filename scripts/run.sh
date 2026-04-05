#!/bin/bash

# Fielsekkia Driver - Run Script with Environment Variables

cd "$(dirname "$0")/.." || exit 1

echo "🚗 Starting Fielsekkia Driver..."
echo "📦 Loading environment from .env..."

/Users/abdallahalawdy/development/flutter/bin/flutter run \
  --dart-define-from-file=.env \
  "$@"
