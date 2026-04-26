#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./build.sh [--isa rv64|rv64f|rv64fd]... [--cores 1] [--out-dir DIR] [--no-coverage] [--clean]

Export OpenC910 smart_run runner artifacts (Verilator backend).

The generated artifacts accept:
  <artifact> --elf PATH [--trace-dir DIR] [--run-dir DIR] [--timeout SEC] [--keep]

Supported: RV64/RV64F/RV64FD labels, one hart, coverage off.
EOF
}

ISAS=()
CORES="1"
OUT_DIR_OPT=""
CLEAN=0
COVERAGE_MODE="none"

die() { echo "ERROR: $*" >&2; exit 1; }

add_isa() {
  local raw="$1"
  local isa
  IFS=',' read -r -a _tmp_isas <<<"${raw}"
  for isa in "${_tmp_isas[@]}"; do
    isa="${isa,,}"
    isa="${isa//[[:space:]]/}"
    [[ -n "${isa}" ]] && ISAS+=("${isa}")
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --isa) [[ $# -ge 2 ]] || die "--isa requires a value"; add_isa "$2"; shift 2; continue ;;
    --isa=*) add_isa "${1#*=}" ;;
    --cores) [[ $# -ge 2 ]] || die "--cores requires a value"; CORES="$2"; shift 2; continue ;;
    --cores=*) CORES="${1#*=}" ;;
    --out-dir) [[ $# -ge 2 ]] || die "--out-dir requires a value"; OUT_DIR_OPT="$2"; shift 2; continue ;;
    --out-dir=*) OUT_DIR_OPT="${1#*=}" ;;
    --coverage) COVERAGE_MODE="full" ;;
    --coverage-light) COVERAGE_MODE="light" ;;
    --no-coverage) COVERAGE_MODE="none" ;;
    --clean) CLEAN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

if [[ ${#ISAS[@]} -eq 0 ]]; then
  ISAS=(rv64)
fi

if [[ "${CORES}" != "1" ]]; then
  echo "ERROR: OpenC910 (cx-build) supports --cores 1 only (got: ${CORES}); use cx-2hart-build for dual hart" >&2
  exit 2
fi
if [[ "${COVERAGE_MODE}" != "none" ]]; then
  echo "ERROR: OpenC910 coverage builds are not supported yet" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMART_DIR="${ROOT_DIR}/smart_run"
OUT_DIR_DEFAULT="${ROOT_DIR}/build_result"
OUT_DIR="${OUT_DIR_OPT:-${CX_OUT_DIR:-${OUT_DIR:-${OUT_DIR_DEFAULT}}}}"

mkdir -p "${OUT_DIR}"

validate_isa() {
  case "$1" in
    rv64|rv64f|rv64fd) ;;
    *) echo "ERROR: OpenC910 integration supports --isa rv64, rv64f, rv64fd only (got: $1)" >&2; exit 2 ;;
  esac
}

# Build the Verilator simulator (CX_TRACE-enabled) once.
build_verilator() {
  command -v verilator >/dev/null 2>&1 || die "verilator not found in PATH"

  local vtop="${SMART_DIR}/work/obj_dir/Vtop"
  if (( CLEAN )); then
    rm -rf "${SMART_DIR}/work"
  fi
  if [[ -x "${vtop}" ]]; then
    return 0
  fi

  mkdir -p "${SMART_DIR}/work"
  echo "[openc910] verilating with CX_TRACE..."
  make -C "${SMART_DIR}" compile \
    SIM=verilator \
    THREADS="${CX_VERILATOR_THREADS:-4}" \
    CODE_BASE_PATH="${ROOT_DIR}/C910_RTL_FACTORY" \
    SIMULATOR_DEF="-cc --exe --top-module top +define+CX_TRACE"
  echo "[openc910] compiling Vtop..."
  make -C "${SMART_DIR}" buildVerilator \
    THREADS="${CX_VERILATOR_THREADS:-4}"

  [[ -x "${vtop}" ]] || die "Vtop binary missing after build: ${vtop}"
}

emit_runner() {
  local isa="$1"
  local artifact_name="openc910_${isa}_${CORES}c"
  local out_file="${OUT_DIR}/${artifact_name}"

  if (( CLEAN )); then
    rm -f "${out_file}"
  fi

  cat >"${out_file}" <<'RUNNER'
#!/usr/bin/env bash
set -euo pipefail

SELF="$(readlink -f "$0")"
CORE_ROOT="${CX_OPENC910_ROOT:-$(cd "$(dirname "${SELF}")/../cores/openc910" 2>/dev/null && pwd || true)}"
if [[ -z "${CORE_ROOT}" || ! -d "${CORE_ROOT}/smart_run" ]]; then
  CORE_ROOT="__CORE_ROOT__"
fi

ELF=""
TRACE_DIR=""
RUN_DIR=""
TIMEOUT_SEC="${CX_OPENCORE_TIMEOUT_SEC:-360}"
KEEP=0

usage() {
  cat <<'EOF'
Usage: __ARTIFACT_NAME__ --elf PATH [--trace-dir DIR] [--run-dir DIR] [--timeout SEC] [--keep]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --elf) ELF="$2"; shift 2; continue ;;
    --elf=*) ELF="${1#*=}" ;;
    --trace-dir) TRACE_DIR="$2"; shift 2; continue ;;
    --trace-dir=*) TRACE_DIR="${1#*=}" ;;
    --run-dir) RUN_DIR="$2"; shift 2; continue ;;
    --run-dir=*) RUN_DIR="${1#*=}" ;;
    --timeout) TIMEOUT_SEC="$2"; shift 2; continue ;;
    --timeout=*) TIMEOUT_SEC="${1#*=}" ;;
    --keep) KEEP=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      if [[ -z "${ELF}" && -f "$1" ]]; then
        ELF="$1"
      else
        echo "ERROR: Unknown argument: $1" >&2
        usage
        exit 2
      fi
      ;;
  esac
  shift
done

[[ -n "${ELF}" ]] || { echo "ERROR: --elf is required" >&2; exit 2; }
[[ -f "${ELF}" ]] || { echo "ERROR: ELF not found: ${ELF}" >&2; exit 2; }
[[ -d "${CORE_ROOT}/smart_run" ]] || { echo "ERROR: OpenC910 smart_run not found under ${CORE_ROOT}" >&2; exit 2; }
if [[ -z "${TOOL_EXTENSION:-}" && -n "${RISCV:-}" ]]; then
  TOOL_EXTENSION="${RISCV}/bin"
fi
[[ -n "${TOOL_EXTENSION:-}" ]] || { echo "ERROR: TOOL_EXTENSION must point to riscv64-unknown-elf toolchain bin directory, or RISCV must point to the RISC-V toolchain prefix" >&2; exit 2; }
command -v timeout >/dev/null 2>&1 || { echo "ERROR: timeout command is required" >&2; exit 2; }

VTOP="${CORE_ROOT}/smart_run/work/obj_dir/Vtop"
[[ -x "${VTOP}" ]] || { echo "ERROR: Vtop binary missing at ${VTOP} (run build.sh)" >&2; exit 2; }

TRACE_DIR="${TRACE_DIR:-${PWD}}"
RUN_DIR="${RUN_DIR:-$(mktemp -d /tmp/openc910-run.XXXXXX)}"
mkdir -p "${TRACE_DIR}" "${RUN_DIR}" "${RUN_DIR}/work"
if (( KEEP == 0 )); then
  trap 'rm -rf "${RUN_DIR}"' EXIT
fi

SMART="${CORE_ROOT}/smart_run"
WORK="${RUN_DIR}/work"
OBJCOPY="${TOOL_EXTENSION}/riscv64-unknown-elf-objcopy"
OBJDUMP="${TOOL_EXTENSION}/riscv64-unknown-elf-objdump"
CONVERT="${SMART}/tests/bin/Srec2vmem"
CONVERT_EXEC="${WORK}/Srec2vmem"
TRACE_FILE="${TRACE_DIR}/openc910_trace_hart_00000000.log"

[[ -x "${OBJCOPY}" ]] || { echo "ERROR: objcopy not executable: ${OBJCOPY}" >&2; exit 2; }
[[ -f "${CONVERT}" ]] || { echo "ERROR: Srec2vmem not found: ${CONVERT}" >&2; exit 2; }
cp "${CONVERT}" "${CONVERT_EXEC}"
chmod +x "${CONVERT_EXEC}"

cp "${ELF}" "${WORK}/case.elf"
"${OBJDUMP}" -S -Mnumeric "${WORK}/case.elf" > "${WORK}/case.obj" || true
"${OBJCOPY}" -O srec "${WORK}/case.elf" "${WORK}/case_inst.hex" -j .text* -j .rodata* -j .eh_frame*
"${OBJCOPY}" -O srec "${WORK}/case.elf" "${WORK}/case_data.hex" -j .data* -j .bss -j .COMMON
"${CONVERT_EXEC}" "${WORK}/case_inst.hex" "${WORK}/inst.pat"
"${CONVERT_EXEC}" "${WORK}/case_data.hex" "${WORK}/data.pat"

(
  cd "${WORK}"
  : > "${TRACE_FILE}"
  timeout "${TIMEOUT_SEC}" "${VTOP}" "+cx_trace=${TRACE_FILE}"
)
RUNNER

  sed -i "s#__CORE_ROOT__#${ROOT_DIR}#g; s#__ARTIFACT_NAME__#${artifact_name}#g" "${out_file}"
  chmod +x "${out_file}"
  echo "Exported ${out_file}"
}

build_verilator

for isa in "${ISAS[@]}"; do
  validate_isa "${isa}"
  emit_runner "${isa}"
done
