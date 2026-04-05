#!/bin/bash
# setup-ios-env.sh
# Reads .env and generates ios/Flutter/FlutterEnv.xcconfig
# Run this once after cloning or when .env changes.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
ENV_FILE="$ROOT_DIR/.env"
XCCONFIG_FILE="$ROOT_DIR/ios/Flutter/FlutterEnv.xcconfig"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

DART_DEFINES=""
while IFS='=' read -r key value || [[ -n "$key" ]]; do
  # Skip comments and empty lines
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${key// }" ]] && continue
  # Encode KEY=VALUE as base64
  ENCODED=$(printf '%s' "${key}=${value}" | base64 | tr -d '\n')
  [ -z "$DART_DEFINES" ] && DART_DEFINES="$ENCODED" || DART_DEFINES="${DART_DEFINES},${ENCODED}"
done < "$ENV_FILE"

cat > "$XCCONFIG_FILE" << EOF
// FlutterEnv.xcconfig — Auto-generated from .env — DO NOT COMMIT
DART_DEFINES=$DART_DEFINES
EOF

echo "✅ FlutterEnv.xcconfig generated at: $XCCONFIG_FILE"
