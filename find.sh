#!/bin/bash
##
# This script attempts to find constants that are unreferenced within
# a codebase.
#
# Usage: ./find.sh <directory>
##

bootstrap() {
  set -euEo pipefail

  if [ -z "${1:-}" ]; then
    echo "Usage: $0 <file|directory>" >&2
    exit 1
  fi

  if [ ! -e "$1" ]; then
    echo "File or directory does not exist: $1" >&2
    exit 1
  fi

  BASE_DIR=${1%/}
  
  _log "Directory: $BASE_DIR"
}

_log() {
  echo "$@"
}

find_constants() {
  _log "Finding constants..."

  CONSTANTS=$(grep -aiP 'const\s{1,}[a-zA-Z0-9_]+\s{0,}=' $BASE_DIR -r --include="*.php" --include="*.ctp" --exclude-dir="vendor")
}

find_unused_constants() {
  _log "Searching for unused constants..."

  IFS=$'\n'
  for LINE in $CONSTANTS; do
    CONSTANT=$(echo $LINE | sed -e 's#.*:.*const\s\{1,\}\([a-zA-Z_0-9_]\+\)\s\{0,\}=.*#\1#i')

    set +e

    grep -ai "$CONSTANT" $BASE_DIR -r \
      --include="*.php" \
      --include="*.ctp" \
      --exclude-dir="vendor" \
      | grep -aiqP 'const\s{1,}[a-zA-Z0-9_]+\s{0,}=' -v \
      > /dev/null

    # If grep returns with no matches, output the file as potentially unused.
    if [ 1 -eq $? ]; then
      FILE=$(echo $LINE | sed -e 's_\([^:]*\):.*_\1_')
      echo "${FILE/#$BASE_DIR\//} : $CONSTANT"
    fi

    set -e
  done
}

main() {
  bootstrap "$@"
  find_constants
  find_unused_constants
}

main "$@"