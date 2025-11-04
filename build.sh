#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build_result"

THREADS="${THREADS:-4}"
SIM_OPT="${SIM_OPT:--x-assign 0 -Wno-fatal --threads ${THREADS} -Wno-TIMESCALEMOD --timing}"

CODE_BASE_PATH="${CODE_BASE_PATH:-$(cd "${ROOT_DIR}/C910_RTL_FACTORY" && pwd)}"
export CODE_BASE_PATH

export TOOL_EXTENSION="${TOOL_EXTENSION:-/opt/riscv/bin}"
export SREC2VMEM="${SREC2VMEM:-${ROOT_DIR}/smart_run/tests/bin/Srec2vmem}"

echo "[build] CODE_BASE_PATH=${CODE_BASE_PATH}"
echo "[build] TOOL_EXTENSION=${TOOL_EXTENSION}"
echo "[build] SREC2VMEM=${SREC2VMEM}"
echo "[build] THREADS=${THREADS}"
echo "[build] SIM_OPT=${SIM_OPT}"

mkdir -p "${BUILD_DIR}"
mkdir -p "${ROOT_DIR}/smart_run/work"

(
  set -x
  make -C "${ROOT_DIR}/smart_run" cleanVerilator
  ENABLE_COMMIT_LOG=1 make -C "${ROOT_DIR}/smart_run" compile SIM=verilator THREADS="${THREADS}" SIMULATOR_OPT="${SIM_OPT}"
  ENABLE_COMMIT_LOG=1 make -C "${ROOT_DIR}/smart_run" buildVerilator
)

VTOP_SRC="${ROOT_DIR}/smart_run/work/obj_dir/Vtop"
if [[ ! -x "${VTOP_SRC}" ]]; then
  echo "[build] error: Verilator binary not found at ${VTOP_SRC}" >&2
  exit 1
fi

cp "${VTOP_SRC}" "${BUILD_DIR}/Vtop"
echo "[build] Vtop copied to ${BUILD_DIR}/Vtop"
echo "[build] Done."
