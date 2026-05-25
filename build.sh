#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./build.sh [--isa rv64|rv64f|rv64fd]... [--cores 1]
                  [--coverage|--coverage-light|--no-coverage]
                  [--out-dir DIR] [--clean]

Export OpenC910 smart_run Verilator binaries.

Coverage modes share the same simulator interface but use distinct Vtop binaries
built with different Verilator flags:
  --no-coverage     Vtop                   (artifact suffix: '')
  --coverage-light  Vtop with line+user    (artifact suffix: _cov_light)
  --coverage        Vtop with full coverage (artifact suffix: _cov)

The generated artifacts are the actual `Vtop` ELFs. Runtime support such as
`Srec2vmem` is staged separately by scripts/stage_runtime_support.sh.
Supported: RV64/RV64F/RV64FD labels, one hart.
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMART_DIR="${ROOT_DIR}/smart_run"
OUT_DIR_DEFAULT="${ROOT_DIR}/build_result"
OUT_DIR="${OUT_DIR_OPT:-${CX_OUT_DIR:-${OUT_DIR:-${OUT_DIR_DEFAULT}}}}"

mkdir -p "${OUT_DIR}"

cov_suffix() {
  case "$1" in
    none)  echo "" ;;
    light) echo "_cov_light" ;;
    full)  echo "_cov" ;;
  esac
}

work_subdir() {
  case "$1" in
    none)  echo "work" ;;
    light) echo "work_cov_light" ;;
    full)  echo "work_cov" ;;
  esac
}

extra_vlt_args_for_mode() {
  case "$1" in
    none)  echo "" ;;
    light) echo "--coverage-line --coverage-user --coverage-max-width 0" ;;
    full)  echo "--coverage" ;;
  esac
}

validate_isa() {
  case "$1" in
    rv64|rv64f|rv64fd) ;;
    *) echo "ERROR: OpenC910 integration supports --isa rv64, rv64f, rv64fd only (got: $1)" >&2; exit 2 ;;
  esac
}

# Build the Verilator simulator for the given coverage mode into its own
# work_<mode> directory so the three modes can coexist on disk.
build_verilator() {
  command -v verilator >/dev/null 2>&1 || die "verilator not found in PATH"

  local mode="$1"
  local subdir
  subdir="$(work_subdir "${mode}")"
  local work_dir="${SMART_DIR}/${subdir}"
  local vtop="${work_dir}/obj_dir/Vtop"

  if (( CLEAN )); then
    rm -rf "${work_dir}"
  fi
  if [[ -x "${vtop}" ]]; then
    return 0
  fi

  # The smart_run Makefile hard-codes ./work as its build directory.
  # For non-default coverage modes we relocate that directory aside,
  # build into ./work, then move the result into work_<mode>.
  local stash_dir=""
  if [[ "${subdir}" != "work" ]]; then
    if [[ -e "${SMART_DIR}/work" ]]; then
      stash_dir="${SMART_DIR}/work.stash.$$"
      mv "${SMART_DIR}/work" "${stash_dir}"
    fi
    mkdir -p "${SMART_DIR}/work"
  else
    mkdir -p "${SMART_DIR}/work"
  fi

  local extra
  extra="$(extra_vlt_args_for_mode "${mode}")"

  echo "[openc910] verilating with CX_TRACE (mode=${mode})..."
  make -C "${SMART_DIR}" compile \
    SIM=verilator \
    THREADS="${CX_VERILATOR_THREADS:-4}" \
    CODE_BASE_PATH="${ROOT_DIR}/C910_RTL_FACTORY" \
    SIMULATOR_DEF="-cc --exe --top-module top +define+CX_TRACE ${extra}"
  echo "[openc910] compiling Vtop (mode=${mode})..."
  make -C "${SMART_DIR}" buildVerilator \
    THREADS="${CX_VERILATOR_THREADS:-4}"

  if [[ "${subdir}" != "work" ]]; then
    rm -rf "${work_dir}"
    mv "${SMART_DIR}/work" "${work_dir}"
    if [[ -n "${stash_dir}" ]]; then
      mv "${stash_dir}" "${SMART_DIR}/work"
    fi
  fi

  [[ -x "${vtop}" ]] || die "Vtop binary missing after build: ${vtop}"
}

emit_binary() {
  local isa="$1"
  local mode="$2"
  local subdir
  subdir="$(work_subdir "${mode}")"
  local suffix
  suffix="$(cov_suffix "${mode}")"
  local artifact_name="openc910_${isa}_${CORES}c${suffix}"
  local out_file="${OUT_DIR}/${artifact_name}"

  if (( CLEAN )); then
    rm -f "${out_file}"
  fi

  local vtop="${SMART_DIR}/${subdir}/obj_dir/Vtop"
  [[ -x "${vtop}" ]] || die "Vtop binary missing after build: ${vtop}"
  cp -f "${vtop}" "${out_file}"
  chmod +x "${out_file}"
  echo "Exported ${out_file}"
}

build_verilator "${COVERAGE_MODE}"

for isa in "${ISAS[@]}"; do
  validate_isa "${isa}"
  emit_binary "${isa}" "${COVERAGE_MODE}"
done
