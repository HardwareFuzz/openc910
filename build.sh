#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build_result"

# Auto-detect number of CPU cores, fallback to 4 if detection fails
NPROC_CORES="$(nproc --all 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
THREADS="${THREADS:-${NPROC_CORES}}"
# Set DEBUG_PC_TRACE=1 to enable detailed PC trace debugging (default: 0 = only show COMMIT)
DEBUG_PC_TRACE="${DEBUG_PC_TRACE:-0}"
# Set DISABLE_ALL_FUSION=1 to disable all instruction fusion (default: 1 = disabled for debugging)
DISABLE_ALL_FUSION="${DISABLE_ALL_FUSION:-1}"
# Set REG_WRITE_LOG=1 to enable x/f register write logging by default (guarded by C910_LOGGER)
REG_WRITE_LOG="${REG_WRITE_LOG:-1}"
# Set REG_WRITE_DBG=1 to enable temporary DBG prints (guarded by C910_DBG_XWB), default off
REG_WRITE_DBG="${REG_WRITE_DBG:-0}"
# Set BOOT_DEBUG_LOG=1 to enable very verbose boot/loader logs (guarded by C910_DEBUG_BOOT)
BOOT_DEBUG_LOG="${BOOT_DEBUG_LOG:-0}"

# Build SIM_OPT based on flags
SIM_OPT_BASE="-x-assign 0 -Wno-fatal --threads ${THREADS} --verilate-jobs ${THREADS} -j ${THREADS} -Wno-TIMESCALEMOD --timing"
if [ "$DEBUG_PC_TRACE" = "1" ]; then
  SIM_OPT_BASE="-DDEBUG_PC_TRACE ${SIM_OPT_BASE}"
fi
if [ "$DISABLE_ALL_FUSION" = "1" ]; then
  SIM_OPT_BASE="-DDISABLE_ALL_FUSION ${SIM_OPT_BASE}"
fi
if [ "$REG_WRITE_LOG" = "1" ]; then
  # Enable retire-time x/f register write logging (testbench + RTL guards)
  SIM_OPT_BASE="-DC910_LOGGER ${SIM_OPT_BASE}"
fi
if [ "$REG_WRITE_DBG" = "1" ]; then
  SIM_OPT_BASE="-DC910_DBG_XWB ${SIM_OPT_BASE}"
fi
if [ "$BOOT_DEBUG_LOG" = "1" ]; then
  SIM_OPT_BASE="-DC910_DEBUG_BOOT ${SIM_OPT_BASE}"
fi
SIM_OPT="${SIM_OPT:-${SIM_OPT_BASE}}"

CODE_BASE_PATH="${CODE_BASE_PATH:-$(cd "${ROOT_DIR}/C910_RTL_FACTORY" && pwd)}"
export CODE_BASE_PATH

export TOOL_EXTENSION="${TOOL_EXTENSION:-/opt/riscv/bin}"
export SREC2VMEM="${SREC2VMEM:-${ROOT_DIR}/smart_run/tests/bin/Srec2vmem}"

echo "[build] CODE_BASE_PATH=${CODE_BASE_PATH}"
echo "[build] TOOL_EXTENSION=${TOOL_EXTENSION}"
echo "[build] SREC2VMEM=${SREC2VMEM}"
echo "[build] THREADS=${THREADS} (detected ${NPROC_CORES} cores)"
echo "[build] SIM_OPT=${SIM_OPT}"
echo "[build] REG_WRITE_LOG=${REG_WRITE_LOG} (adds -DC910_LOGGER)"
echo "[build] REG_WRITE_DBG=${REG_WRITE_DBG} (adds -DC910_DBG_XWB)"
echo "[build] BOOT_DEBUG_LOG=${BOOT_DEBUG_LOG} (adds -DC910_DEBUG_BOOT)"

mkdir -p "${BUILD_DIR}"
mkdir -p "${ROOT_DIR}/smart_run/work"

(
  set -x
  # Prepare resolved filelist for Verilator (expand ${CODE_BASE_PATH})
  SRC_FL="${CODE_BASE_PATH}/gen_rtl/filelists/C910_asic_rtl.fl"
  DST_FL="${ROOT_DIR}/smart_run/work/C910_asic_rtl.resolved.fl"
  sed "s#\\\${CODE_BASE_PATH}#${CODE_BASE_PATH}#g" "${SRC_FL}" > "${DST_FL}"
  echo "[build] Resolved filelist -> ${DST_FL}"
  make -C "${ROOT_DIR}/smart_run" cleanVerilator
  ENABLE_COMMIT_LOG=1 make -C "${ROOT_DIR}/smart_run" compile SIM=verilator THREADS="${THREADS}" SIMULATOR_OPT="${SIM_OPT}"
  # Use parallel make with all available cores for building the C++ files
  ENABLE_COMMIT_LOG=1 make -j"${THREADS}" -C "${ROOT_DIR}/smart_run" buildVerilator
)

VTOP_SRC="${ROOT_DIR}/smart_run/work/obj_dir/Vtop"
if [[ ! -x "${VTOP_SRC}" ]]; then
  echo "[build] error: Verilator binary not found at ${VTOP_SRC}" >&2
  exit 1
fi

cp "${VTOP_SRC}" "${BUILD_DIR}/Vtop"
echo "[build] Vtop copied to ${BUILD_DIR}/Vtop"
echo "[build] Done."
