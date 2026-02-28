#!/bin/sh

set -e

echo "Starting ci_post_clone.sh script..."

# Secrets.xcconfig 파일 생성 경로
CONFIG_PATH="${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret/Secrets.xcconfig"

echo "Creating Secrets.xcconfig at: $CONFIG_PATH"

# Core/Secret 디렉토리가 없을 경우 생성
mkdir -p "${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret"

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
echo "File contents:"
cat "$CONFIG_PATH"
