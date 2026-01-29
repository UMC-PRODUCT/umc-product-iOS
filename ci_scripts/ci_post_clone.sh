#!/bin/sh

set -e

echo "Starting ci_post_clone.sh script..."

# Secrets.xcconfig 파일 생성 경로
CONFIG_PATH="${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret/Secrets.xcconfig"

echo "Creating Secrets.xcconfig at: $CONFIG_PATH"

# Core/Secret 디렉토리가 없을 경우 생성
mkdir -p "${CI_WORKSPACE}/AppProduct/AppProduct/Core/Secret"

# App Store Connect에 등록한 환경 변수로 xcconfig 생성
cat > "$CONFIG_PATH" << EOF
EOF

echo "Secrets.xcconfig created successfully"
echo "File contents:"
cat "$CONFIG_PATH"
