#!/bin/sh

set -e

echo "Starting ci_post_clone.sh script..."

# Secrets.xcconfig 파일 생성 경로
CONFIG_PATH="${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret/Secrets.xcconfig"
# Firebase 설정 파일 복원 경로
FIREBASE_PLIST_PATH="${CI_WORKSPACE}/AppProduct/AppProduct/GoogleService-Info.plist"

echo "Creating Secrets.xcconfig at: $CONFIG_PATH"

# Core/Secret 디렉토리가 없을 경우 생성
mkdir -p "${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret"

# base64 디코드 호환 함수 (macOS: -D, GNU: --decode)
decode_base64() {
  input="$1"

  if printf "%s" "$input" | base64 --decode >/dev/null 2>&1; then
    printf "%s" "$input" | base64 --decode
    return 0
  fi

  if printf "%s" "$input" | base64 -D >/dev/null 2>&1; then
    printf "%s" "$input" | base64 -D
    return 0
  fi

  return 1
}

# BASE_URL 하위 호환:
# - 권장: BASE_URL_DEBUG / BASE_URL_RELEASE
# - 레거시: BASE_URL (둘 다 동일 값으로 사용)
BASE_URL_DEBUG_VALUE="${BASE_URL_DEBUG:-${BASE_URL}}"
BASE_URL_RELEASE_VALUE="${BASE_URL_RELEASE:-${BASE_URL}}"

if [ -z "$BASE_URL_DEBUG_VALUE" ] || [ -z "$BASE_URL_RELEASE_VALUE" ]; then
  echo "ERROR: BASE_URL_DEBUG/BASE_URL_RELEASE (or BASE_URL) environment variables are required."
  exit 1
fi

# xcconfig에서는 '//'가 주석이므로 URL을 https:/$()/... 형식으로 변환
to_xcconfig_url() {
  printf "%s" "$1" | sed 's#://#:/$()/#'
}

BASE_URL_DEBUG_XCCONFIG="$(to_xcconfig_url "$BASE_URL_DEBUG_VALUE")"
BASE_URL_RELEASE_XCCONFIG="$(to_xcconfig_url "$BASE_URL_RELEASE_VALUE")"

# App Store Connect에 등록한 환경 변수로 xcconfig 생성
cat > "$CONFIG_PATH" << EOF
KAKAO_KEY=${KAKAO_KEY}
BASE_URL=${BASE_URL_RELEASE_XCCONFIG}
BASE_URL[config=Debug]=${BASE_URL_DEBUG_XCCONFIG}
BASE_URL[config=Release]=${BASE_URL_RELEASE_XCCONFIG}
TMAP_SECRET_KEY=${TMAP_SECRET_KEY}
EOF

echo "Secrets.xcconfig created successfully"
echo "Secrets.xcconfig created successfully at: $CONFIG_PATH"

# Firebase GoogleService-Info.plist 복원
# - 권장: GOOGLE_SERVICE_INFO_PLIST_BASE64
# - 대안: GOOGLE_SERVICE_INFO_PLIST_CONTENT (raw xml)
if [ -n "$GOOGLE_SERVICE_INFO_PLIST_BASE64" ]; then
  echo "Restoring GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_BASE64..."
  if ! decode_base64 "$GOOGLE_SERVICE_INFO_PLIST_BASE64" > "$FIREBASE_PLIST_PATH"; then
    echo "ERROR: Failed to decode GOOGLE_SERVICE_INFO_PLIST_BASE64"
    exit 1
  fi
elif [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
  echo "Restoring GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_CONTENT..."
  printf "%s" "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > "$FIREBASE_PLIST_PATH"
else
  echo "ERROR: Firebase config is required. Set GOOGLE_SERVICE_INFO_PLIST_BASE64 in Xcode Cloud environment variables."
  exit 1
fi

if ! grep -q "<plist" "$FIREBASE_PLIST_PATH"; then
  echo "ERROR: Restored GoogleService-Info.plist does not look like a plist file."
  exit 1
fi

echo "GoogleService-Info.plist restored successfully at: $FIREBASE_PLIST_PATH"
