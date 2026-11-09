#!/usr/bin/env bash
set -euo pipefail
echo 'Tum yerel baglantilari ac: bash connect.sh'
echo 'Tum adresler ve giris bilgileri: bash get-connections.sh'
bash "$(dirname -- "${BASH_SOURCE[0]}")/get-connections.sh" --no-secrets
