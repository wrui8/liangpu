#!/usr/bin/env bash
# 良扑 iOS 未签名 IPA 构建脚本（必须在 macOS + Xcode 上运行）
#
# 产物：dist/liangpu-ios-<version>-unsigned.ipa
# 未签名 IPA 不能直接安装到未越狱 iPhone：需要用 Sideloadly / AltStore 等工具
# 以用户自己的 Apple ID 重签名后再装，然后在「设置 → 通用 → VPN与设备管理」里点信任。
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "✗ iOS 构建需要 macOS + Xcode；当前系统：$(uname)" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app"

VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//' | cut -d+ -f1)"

flutter pub get
flutter build ios --release --no-codesign

APP_PATH="build/ios/iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✗ 未找到 $APP_PATH" >&2
  exit 1
fi

STAGE="build/ios/ipa-payload"
OUT="$ROOT/dist/liangpu-ios-${VERSION}-unsigned.ipa"
rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
cp -R "$APP_PATH" "$STAGE/Payload/Runner.app"
mkdir -p "$ROOT/dist"

# ditto 能保留符号链接与资源分叉，比 zip 更适合打 ipa
ditto -c -k --sequesterRsrc --keepParent "$STAGE/Payload" "$OUT"

echo "✓ 已生成：$OUT"
echo "  安装：用 Sideloadly 导入该 IPA，登录自己的 Apple ID 重签名后装到 iPhone，"
echo "       再到「设置 → 通用 → VPN与设备管理」信任对应开发者描述文件。"
