#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" exec deployment/dashboard -- python /consumer/client.py
