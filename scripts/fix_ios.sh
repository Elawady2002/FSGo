#!/bin/bash

# Navigate to project root
cd "$(dirname "$0")/.."

echo "🔥 STARTING MAGIC IOS REPAIR (Extreme Version) 🔥"

# 1. Clean Flutter build artifacts
echo "🧹 Cleaning Flutter..."
flutter clean

# 2. Cleanup iOS specific files
echo "🗑️ Removing Pods and Locks..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf build/
rm -rf ios/DerivedData

# 3. Kill Xcode and Clear DerivedData
echo "🚫 Closing Xcode and clearing DerivedData..."
killall Xcode 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/fi-el-sekka-*
rm -rf ~/Library/Caches/CocoaPods

# 4. Reset Simulator (Optional but helpful)
# xcrun simctl shutdown all
# xcrun simctl erase all

# 5. Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# 6. Re-install Pods with forced repo update
echo "🛠️ Re-installing Pods..."
cd ios
# We use arch -x86_64 if on M1/M2 but typically pod install is enough
pod install --repo-update

# 7. Final Sanity Check for Scripts
echo "🔍 Verifying script patches..."
if grep -q "python3 -c" Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-frameworks.sh; then
    echo "✅ Scripts are successfully patched!"
else
    echo "⚠️ Scripts might not be patched. Try running pod install again."
fi

echo "✨ FIX COMPLETE! ✨"
echo "Advice: Restart your Mac or at least Xcode."
echo "Try building now from Xcode or with 'flutter run'."
