#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'OpenMetadata kullanici: admin@open-metadata.org'
k -n "$RM8_NAMESPACE" get secret rm8-governance -o 'jsonpath={.data.admin-password}' | base64 --decode
printf '\n%s\n' 'Parolayi paylasmayin. Once bash connect-catalog.sh tunelini baslatin.'
