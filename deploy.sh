#!/bin/sh
set -eu

cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

FLUTTER_BIN=${FLUTTER_BIN:-flutter}
DART_BIN=${DART_BIN:-dart}
export FLUTTER_BIN

for executable in "$FLUTTER_BIN" "$DART_BIN"; do
  if ! command -v "$executable" >/dev/null 2>&1; then
    printf '실행 파일을 찾을 수 없습니다: %s\nFlutter SDK의 bin 경로를 PATH에 추가해 주세요.\n' "$executable" >&2
    exit 1
  fi
done

# Dart 실행 도구에서 로컬 웹·실기기 실행 또는 정적 호스팅 빌드를 선택합니다.
exec "$DART_BIN" tool/deploy.dart "$@"
