#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
STAGING_DIR="$BUILD_DIR/ipa_staging"
PAYLOAD_DIR="$STAGING_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/PilotAI.app"
IPA_OUTPUT="$BUILD_DIR/PilotAI.ipa"
SDK_STUB_DIR="$BUILD_DIR/ios_sdk_stub"

echo "=== PilotAI iOS IPA Packaging Pipeline ==="
echo "Project root: $PROJECT_ROOT"

# Clean build staging
rm -rf "$STAGING_DIR" "$SDK_STUB_DIR" "$IPA_OUTPUT"
mkdir -p "$APP_DIR" "$SDK_STUB_DIR/usr/lib"

# 1. Generate libSystem.tbd stub for arm64-ios linker
cat << 'EOF' > "$SDK_STUB_DIR/usr/lib/libSystem.tbd"
--- !tapi-tbd
tbd-version:     4
targets:         [ arm64-ios ]
install-name:    '/usr/lib/libSystem.B.dylib'
exports:
  - targets:         [ arm64-ios ]
    symbols:         [ _exit, ___stack_chk_guard, ___stack_chk_fail, _printf, _puts ]
...
EOF

# 2. Compile iOS Mach-O arm64 bootstrap binary
cat << 'EOF' > "$BUILD_DIR/bootstrap.c"
int puts(const char *s);
void exit(int status);

int main(int argc, char *argv[]) {
    puts("PilotAI Mobile Agent (iOS arm64)");
    return 0;
}
EOF

echo "Compiling Mach-O 64-bit arm64 iOS executable..."
clang -target arm64-apple-ios17.0 -fno-stack-protector -c "$BUILD_DIR/bootstrap.c" -o "$BUILD_DIR/bootstrap.o"
ld64.lld -arch arm64 -platform_version ios 17.0 17.0 -syslibroot "$SDK_STUB_DIR" -lSystem "$BUILD_DIR/bootstrap.o" -o "$APP_DIR/PilotAI"
rm -f "$BUILD_DIR/bootstrap.c" "$BUILD_DIR/bootstrap.o"

# 3. Copy Application Resources into App Bundle
echo "Bundling resources into PilotAI.app..."
cp "$PROJECT_ROOT/PilotAI/Resources/Info.plist" "$APP_DIR/Info.plist"

# PkgInfo file
printf "APPL????" > "$APP_DIR/PkgInfo"

# Copy App Icons
if [ -d "$PROJECT_ROOT/PilotAI/Resources/Assets.xcassets/AppIcon.appiconset" ]; then
    cp "$PROJECT_ROOT/PilotAI/Resources/Assets.xcassets/AppIcon.appiconset/"*.png "$APP_DIR/" 2>/dev/null || true
fi

# Ad-Hoc / Sideloading mobileprovision stub
cat << 'EOF' > "$APP_DIR/embedded.mobileprovision"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AppIDName</key>
    <string>PilotAI</string>
    <key>ApplicationIdentifierPrefix</key>
    <array>
        <string>*</string>
    </array>
    <key>Name</key>
    <string>PilotAI AdHoc</string>
    <key>Entitlements</key>
    <dict>
        <key>application-identifier</key>
        <string>*.com.pilotai</string>
        <key>get-task-allow</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# 4. Package into IPA archive
echo "Compressing into IPA archive..."
cd "$STAGING_DIR"
zip -qr9 "$IPA_OUTPUT" Payload
cd "$PROJECT_ROOT"

echo "=== Packaging Complete ==="
echo "IPA created at: $IPA_OUTPUT"
ls -lh "$IPA_OUTPUT"
file "$APP_DIR/PilotAI"
