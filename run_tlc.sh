#!/usr/bin/env bash
# Reproduce the Merkle Agreement verification runs.
# Usage: ./run_tlc.sh /path/to/tla2tools.jar
set -euo pipefail

JAR="${1:-tla2tools.jar}"
if [ ! -f "$JAR" ]; then
  echo "tla2tools.jar not found at: $JAR"
  echo "Usage: ./run_tlc.sh /path/to/tla2tools.jar"
  exit 1
fi

mkdir -p logs

run() {
  local cfg="$1" tla="$2" log="$3"
  echo ">>> TLC $tla  (config: $cfg)"
  java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC -config "$cfg" "$tla" > "logs/$log" 2>&1
  echo "    exit=$? -> logs/$log"
  grep -E "states generated|No error has been found|is violated" "logs/$log" | tail -2
  echo
}

run Vortex_DSE_CSlot_AE_tiny.cfg      Vortex_DSE_CSlot_AE.tla  tlc_ae_safety.log
run Vortex_DSE_CSlot_AE_liveness.cfg  Vortex_DSE_CSlot_AE.tla  tlc_ae_liveness.log

# TLC leaves a states/ metadata dir; remove it for a clean tree.
rm -rf states

echo "All runs complete. See STATUS.md and logs/."
