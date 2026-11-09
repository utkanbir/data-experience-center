#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM6_NAMESPACE" delete secret rm6-dbt-service --ignore-not-found=true
printf '%s\n' 'Yerel token kaldirildi. Harici dbt hesabi veya tokeni silinmedi.'
