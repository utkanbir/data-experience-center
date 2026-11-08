#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM5_NAMESPACE" exec deployment/dashboard -- python /consumer/client.py
