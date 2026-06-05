#!/bin/bash
set -e
mkdir -p dist
sed \
  -e "s|__SB_URL__|${SB_URL}|g" \
  -e "s|__SB_KEY__|${SB_KEY}|g" \
  index.html > dist/index.html
echo "Build OK — credenciais injetadas."
