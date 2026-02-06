#!/usr/bin/env bash
set -euo pipefail

REPO_ZIP_URL="https://github.com/prehisle/hada/archive/refs/heads/main.zip"

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

curl -fsSL "$REPO_ZIP_URL" -o "$tmp/a.zip"

if command -v unzip >/dev/null 2>&1; then
  unzip -q "$tmp/a.zip" -d "$tmp"
  top="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [ -z "$top" ]; then
    echo "Failed to find top directory in zip" >&2
    exit 1
  fi
  if command -v tar >/dev/null 2>&1; then
    tar -C "$top" -cf - . | tar -C . -xf -
  else
    cp -a "$top"/. .
  fi
else
  ZIP_PATH="$tmp/a.zip" TMP_DIR="$tmp" python3 - <<'PY'
import os, zipfile, shutil, sys
zip_path = os.environ["ZIP_PATH"]
tmp_dir = os.environ["TMP_DIR"]
with zipfile.ZipFile(zip_path) as z:
    names = z.namelist()
    if not names:
        sys.exit("Empty zip")
    prefix = names[0].split("/", 1)[0] + "/"
    z.extractall(tmp_dir)

top = os.path.join(tmp_dir, prefix.rstrip("/"))
if not os.path.isdir(top):
    sys.exit("Top directory not found")

for name in os.listdir(top):
    src = os.path.join(top, name)
    dst = os.path.join(".", name)
    if os.path.exists(dst):
        if os.path.isdir(dst) and not os.path.islink(dst):
            shutil.rmtree(dst)
        else:
            os.remove(dst)
    shutil.move(src, dst)
PY
fi
