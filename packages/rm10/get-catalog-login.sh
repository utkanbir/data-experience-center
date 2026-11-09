#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'OpenMetadata kullanici: admin@open-metadata.org'
k -n "$RM10_NAMESPACE" get secret rm10-governance -o 'jsonpath={.data.admin-password}' | base64 --decode
printf '\n%s\n' 'Parolayi paylasmayin. Once bash connect-catalog.sh tunelini baslatin.'
