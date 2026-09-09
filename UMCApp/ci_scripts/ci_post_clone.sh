#!/bin/sh
#
#  ci_post_clone.sh
#  UMCApp
#
#  Created by euijjang97 on 9/9/26.
#

# Xcode Cloud 가 클론 직후 실행하는 post-clone 스크립트.
#
# git 미추적 시크릿 두 개를 App Store Connect 환경 변수에서 복원한다.
#   - UMCApp/Secrets/Secrets.xcconfig        (Shared.xcconfig 의 `#include?` 가 끌어옴)
#   - UMCApp/UMCApp/Resources/GoogleService-Info.plist
#
# 생성하는 xcconfig 키는 Shared.xcconfig 가 기본값으로 선언해 둔 것과 같은 집합이어야 한다.
# (KAKAO_KEY / TMAP_SECRET_KEY / GOOGLE_CLIENT_ID / GOOGLE_REVERSED_CLIENT_ID / BASE_URL)
# APS_ENVIRONMENT 처럼 Shared.xcconfig 가 스스로 결정하는 값은 여기서 덮어쓰지 않는다.
#
# 참고: UMCApp 은 Tuist 프로젝트라 xcworkspace 가 레포에 없다. Xcode Cloud 워크플로가
#       UMCApp/UMCApp.xcworkspace 를 빌드하려면 이 스크립트 이후 `tuist generate` 단계가 필요하다.

set -e

echo "Starting ci_post_clone.sh script..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# worktree 는 .git 이 디렉터리가 아니라 파일이므로 -e 로 검사한다.
while [ "$REPO_ROOT" != "/" ] && [ ! -e "$REPO_ROOT/.git" ]; do
  REPO_ROOT="$(dirname "$REPO_ROOT")"
done

if [ "$REPO_ROOT" = "/" ]; then
  # UMCApp/ci_scripts → 레포 루트는 두 단계 위
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

WORKSPACE_ROOT="${CI_WORKSPACE:-$REPO_ROOT}"
echo "Using workspace root: $WORKSPACE_ROOT"

# Secrets.xcconfig 파일 생성 경로
CONFIG_PATH="${WORKSPACE_ROOT}/UMCApp/Secrets/Secrets.xcconfig"
# Firebase 설정 파일 복원 경로
FIREBASE_PLIST_PATH="${WORKSPACE_ROOT}/UMCApp/UMCApp/Resources/GoogleService-Info.plist"

echo "Creating Secrets.xcconfig at: $CONFIG_PATH"

mkdir -p "${WORKSPACE_ROOT}/UMCApp/Secrets"
mkdir -p "${WORKSPACE_ROOT}/UMCApp/UMCApp/Resources"

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

# TestFlight 워크플로는 App Store 워크플로와 똑같이 Release 구성으로 아카이브한다
# (기본 스킴의 Archive 액션이 Release 고정). 그래서 서버만 dev 로 돌리려면 configuration
# 이 아니라 별도 플래그가 필요하다 — APS_ENVIRONMENT 가 같은 축으로 갈려 있어
# configuration 을 Debug 로 바꾸면 푸시가 통째로 깨진다.
#
# App Store Connect 워크플로 전용 환경 변수에 USE_DEV_SERVER=1 을 넣은 워크플로만 해당된다.
# (TF-External-Only · TF-Internal-Only 에만 지정. AppStore-Release 에는 넣지 않는다)
if [ "$USE_DEV_SERVER" = "1" ]; then
  echo "USE_DEV_SERVER=1 — Release 구성에도 dev 베이스 URL 을 주입한다."
  BASE_URL_RELEASE_VALUE="$BASE_URL_DEBUG_VALUE"
fi

if [ -z "$BASE_URL_DEBUG_VALUE" ] || [ -z "$BASE_URL_RELEASE_VALUE" ]; then
  echo "ERROR: BASE_URL_DEBUG/BASE_URL_RELEASE (or BASE_URL) environment variables are required."
  exit 1
fi

if [ -z "$KAKAO_KEY" ]; then
  echo "ERROR: KAKAO_KEY environment variable is required."
  exit 1
fi

if [ -z "$TMAP_SECRET_KEY" ]; then
  echo "ERROR: TMAP_SECRET_KEY environment variable is required."
  exit 1
fi

# Google OAuth (iOS Google Sign-In)
# - GOOGLE_CLIENT_ID 필수 (예: 6550...-xxxx.apps.googleusercontent.com)
# - GOOGLE_REVERSED_CLIENT_ID 미지정 시 CLIENT_ID에서 자동 도출
#   (com.googleusercontent.apps.<unique>)
if [ -z "$GOOGLE_CLIENT_ID" ]; then
  echo "ERROR: GOOGLE_CLIENT_ID environment variable is required."
  exit 1
fi

GOOGLE_REVERSED_CLIENT_ID_VALUE="${GOOGLE_REVERSED_CLIENT_ID:-}"
if [ -z "$GOOGLE_REVERSED_CLIENT_ID_VALUE" ]; then
  GOOGLE_CLIENT_ID_UNIQUE="$(printf "%s" "$GOOGLE_CLIENT_ID" | sed 's/\.apps\.googleusercontent\.com$//')"
  GOOGLE_REVERSED_CLIENT_ID_VALUE="com.googleusercontent.apps.${GOOGLE_CLIENT_ID_UNIQUE}"
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
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_REVERSED_CLIENT_ID=${GOOGLE_REVERSED_CLIENT_ID_VALUE}
EOF

echo "Secrets.xcconfig created successfully at: $CONFIG_PATH"

if ! grep -q '^KAKAO_KEY=' "$CONFIG_PATH" \
  || ! grep -q '^TMAP_SECRET_KEY=' "$CONFIG_PATH" \
  || ! grep -q '^GOOGLE_CLIENT_ID=' "$CONFIG_PATH" \
  || ! grep -q '^GOOGLE_REVERSED_CLIENT_ID=' "$CONFIG_PATH"; then
  echo "ERROR: Secrets.xcconfig validation failed (missing required keys)"
  exit 1
fi

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

if ! plutil -lint "$FIREBASE_PLIST_PATH" >/dev/null 2>&1; then
  echo "ERROR: GoogleService-Info.plist is not a valid plist file."
  exit 1
fi

if ! grep -q "<key>GOOGLE_APP_ID</key>" "$FIREBASE_PLIST_PATH"; then
  echo "ERROR: GOOGLE_APP_ID missing in GoogleService-Info.plist."
  exit 1
fi

echo "GoogleService-Info.plist restored successfully at: $FIREBASE_PLIST_PATH"
