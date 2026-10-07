#!/usr/bin/env bash
set -euo pipefail

readily_root="$(cd "$(dirname "$0")/.." && pwd)"
readily_api_host="${API_HOST:-}"
readily_api_port="${API_PORT:-3000}"

if [[ -z "$readily_api_host" ]]; then
  for readily_interface in en0 en1; do
    readily_candidate="$(ipconfig getifaddr "$readily_interface" 2>/dev/null || true)"
    if [[ -n "$readily_candidate" ]]; then
      readily_api_host="$readily_candidate"
      break
    fi
  done
fi

if [[ -z "$readily_api_host" ]]; then
  echo "Không tìm thấy IP Wi-Fi của Mac."
  echo "Hãy chạy lại với: API_HOST=192.168.x.x ./scripts/build_pixel_apk.sh"
  exit 1
fi

readily_api_url="http://${readily_api_host}:${readily_api_port}/api"

echo "Đang build APK cho Google Pixel"
echo "Backend API: ${readily_api_url}"

cd "$readily_root"
flutter build apk \
  --release \
  --dart-define="API_BASE_URL=${readily_api_url}"

echo
echo "APK đã tạo tại:"
echo "${readily_root}/build/app/outputs/flutter-apk/app-release.apk"
echo
echo "Pixel và Mac phải dùng cùng Wi-Fi, backend phải đang chạy."
