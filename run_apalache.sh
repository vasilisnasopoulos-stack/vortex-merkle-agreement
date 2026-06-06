#!/usr/bin/env bash
# Symbolic (SMT-backed) model check via Apalache.
#   Requires Apalache >= 0.58 and Java 17+.
#   Set APALACHE_BIN to the apalache-mc launcher, or have it on PATH.
#   Usage: ./run_apalache.sh [length]   (default length = 8)
set -euo pipefail
APA="${APALACHE_BIN:-apalache-mc}"
LEN="${1:-8}"
echo ">>> Apalache check  MC_Vortex_DSE_CSlot_AE.tla  (cinit=ConstInit, inv=AllInv, length=$LEN)"
"$APA" check --cinit=ConstInit --inv=AllInv --length="$LEN" MC_Vortex_DSE_CSlot_AE.tla
