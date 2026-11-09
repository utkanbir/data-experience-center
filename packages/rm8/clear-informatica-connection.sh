#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" delete secret rm8-informatica --ignore-not-found=true
echo 'Yerel Secret silindi. Harici JWT iptal edilmez; yeni rapor icin Run-Scenario calistirin.'
