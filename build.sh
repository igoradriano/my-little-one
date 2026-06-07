#!/bin/bash
set -e
mkdir -p dist
sed \
  -e "s|__SB_URL__|${SB_URL}|g" \
  -e "s|__SB_KEY__|${SB_KEY}|g" \
  -e "s|__ADMIN_NAME__|${ADMIN_NAME}|g" \
  -e "s|__ADMIN_PASS__|${ADMIN_PASS}|g" \
  index.html > dist/index.html
echo "Build OK — credenciais injetadas."
