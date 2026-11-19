#!/usr/bin/env bash
# 生成良扑内部 CA 与服务器证书（默认绑定 10.28.13.214）。
# 用法：bash scripts/gen-certs.sh [服务器IP]
# 证书输出到 docker-data/certs/；已有 CA 时会复用，只重签服务器证书。
set -euo pipefail
export MSYS_NO_PATHCONV=1

IP="${1:-10.28.13.214}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/docker-data/certs"
mkdir -p "$DIR"
cd "$DIR"

if [ -f ca.key ] && [ -f ca.pem ]; then
  echo "复用已有 CA：$DIR/ca.pem"
else
  openssl ecparam -name prime256v1 -genkey -noout -out ca.key
  openssl req -x509 -new -key ca.key -sha256 -days 3650 \
    -subj "/CN=Liangpu Internal CA/O=Liangpu" -out ca.pem
  echo "已生成新 CA：$DIR/ca.pem"
fi

openssl ecparam -name prime256v1 -genkey -noout -out server.key
openssl req -new -key server.key -subj "/CN=liangpu.local" -out server.csr
cat > server.ext <<EOF
subjectAltName=IP:${IP},IP:127.0.0.1,DNS:localhost,DNS:liangpu.local
basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
EOF
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
  -days 825 -sha256 -extfile server.ext -out server.crt
rm -f server.csr

echo "服务器证书已生成：$DIR/server.crt"
echo "管理电脑安装根证书：certutil -addstore -user Root \"$DIR/ca.pem\""
