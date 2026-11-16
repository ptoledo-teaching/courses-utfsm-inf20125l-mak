#!/usr/bin/env bash

set -u
export LC_ALL=C
ulimit -c 0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEMP_DIR="$(mktemp -d)" || exit 2
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
PASSES=0
FAILURES=0

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        printf 'PASS: %s\n' "${description}"
        PASSES=$((PASSES + 1))
    else
        printf 'FAIL: %s\n' "${description}"
        FAILURES=$((FAILURES + 1))
    fi
}

is_binary() {
    [[ -f "$1" && -x "$1" ]] || return 1
    [[ "$(file -b -- "$1")" == ELF*executable* ]]
}

matches_tests() {
    local program="$1"
    local input="" expected=""
    local count=0
    is_binary "${program}" || return 1
    for input in "${WORKSPACE}/tests"/test*.in; do
        [[ -f "${input}" ]] || continue
        expected="${input%.in}.expected"
        [[ -f "${expected}" ]] || return 1
        timeout 3 "${program}" < "${input}" > "${TEMP_DIR}/actual.out" 2> "${TEMP_DIR}/actual.err" || return 1
        cmp -s "${expected}" "${TEMP_DIR}/actual.out" || return 1
        [[ ! -s "${TEMP_DIR}/actual.err" ]] || return 1
        count=$((count + 1))
    done
    (( count == TEST_COUNT ))
}

summary() {
    local total=$((PASSES + FAILURES))
    local width="${#total}"
    printf '\n== Resumen ===============================\n\n'
    printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${width}" "${PASSES}"
    printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${width}" "${FAILURES}"
    (( FAILURES == 0 ))
}

TEST_COUNT=4

CHECK_ROOT="${TEMP_DIR}/workspace"
mkdir -p "${CHECK_ROOT}"
cp -a "${WORKSPACE}/." "${CHECK_ROOT}/" || exit 2
CASE_DIR=""
TARGET=""
BUILT=0
OBJECTS=()

prepare_case() {
    CASE_DIR="${CHECK_ROOT}/$1"
    TARGET="$2"
    shift 2
    OBJECTS=("$@")
    BUILT=0
}

build_case() {
    [[ -f "${CASE_DIR}/Makefile" ]] || return 1
    (cd "${CASE_DIR}" && timeout 15 make -B all) || return 1
    local object=""
    for object in "${OBJECTS[@]}"; do
        [[ -f "${CASE_DIR}/${object}" ]] || return 1
    done
    is_binary "${CASE_DIR}/${TARGET}" || return 1
    BUILT=1
}

compile_options() {
    (( BUILT == 1 )) || return 1
    local line="" flag="" count=0
    local plan="${TEMP_DIR}/plan.txt"
    (cd "${CASE_DIR}" && timeout 15 make -Bn all) > "${plan}" || return 1
    while IFS= read -r line; do
        # Acepta comillas alrededor de opciones sin exigir una receta literal.
        line="${line//\'/}"
        line="${line//\"/}"
        [[ " ${line} " == *" -c "* ]] || continue
        for flag in -Wall -Wextra -std=c11 -g -O0; do
            [[ " ${line} " == *" ${flag} "* ]] || return 1
        done
        count=$((count + 1))
    done < "${plan}"
    (( count == ${#OBJECTS[@]} ))
}

dependency_files() {
    (( BUILT == 1 )) || return 1
    local object=""
    for object in "${OBJECTS[@]}"; do
        [[ -s "${CASE_DIR}/${object%.o}.d" ]] || return 1
    done
}

case_matches() {
    (( BUILT == 1 )) || return 1
    if [[ "${TARGET}" == suma ]]; then
        printf '%s\n' 'Suma: 12' > "${TEMP_DIR}/suma.expected"
        timeout 3 "${CASE_DIR}/${TARGET}" > "${TEMP_DIR}/suma.out" || return 1
        cmp -s "${TEMP_DIR}/suma.expected" "${TEMP_DIR}/suma.out"
    elif [[ "${TARGET}" == relay_example ]]; then
        printf '%s\n' 'Relay hoth-relay: checksum=51 strength=119' > "${TEMP_DIR}/relay.expected"
        timeout 3 "${CASE_DIR}/${TARGET}" > "${TEMP_DIR}/relay.out" || return 1
        cmp -s "${TEMP_DIR}/relay.expected" "${TEMP_DIR}/relay.out"
    else
        matches_tests "${CASE_DIR}/${TARGET}"
    fi
}

no_rebuild() {
    (( BUILT == 1 )) || return 1
    local files=("${OBJECTS[@]}" "${TARGET}")
    local before=() name="" index=0
    for name in "${files[@]}"; do
        before+=("$(stat -c %y "${CASE_DIR}/${name}")")
    done
    (cd "${CASE_DIR}" && timeout 15 make) || return 1
    for name in "${files[@]}"; do
        [[ "${before[index]}" == "$(stat -c %y "${CASE_DIR}/${name}")" ]] || return 1
        index=$((index + 1))
    done
}

incremental() {
    (( BUILT == 1 )) || return 1
    local modified="$1"
    local expected=" $2 "
    local before=() object="" index=0 after=""
    local target_before=""
    for object in "${OBJECTS[@]}"; do
        before+=("$(stat -c %y "${CASE_DIR}/${object}")")
    done
    target_before="$(stat -c %y "${CASE_DIR}/${TARGET}")"
    sleep 0.05
    touch "${CASE_DIR}/${modified}" || return 1
    (cd "${CASE_DIR}" && timeout 15 make) || return 1
    for object in "${OBJECTS[@]}"; do
        after="$(stat -c %y "${CASE_DIR}/${object}")"
        if [[ "${expected}" == *" ${object} "* ]]; then
            [[ "${before[index]}" != "${after}" ]] || return 1
        else
            [[ "${before[index]}" == "${after}" ]] || return 1
        fi
        index=$((index + 1))
    done
    [[ "${target_before}" != "$(stat -c %y "${CASE_DIR}/${TARGET}")" ]] || return 1
    case_matches
}

suite_target() {
    (( BUILT == 1 )) || return 1
    local input="" output="" count=0 status=0
    for input in "${CHECK_ROOT}/tests"/test*.in; do
        [[ -f "${input}" ]] || continue
        output="${input%.in}.out"
        rm -f -- "${output}"
    done
    # Un archivo llamado test no debe bloquear el target de acción.
    touch "${CASE_DIR}/test"
    (cd "${CASE_DIR}" && timeout 15 make test) || return 1
    for input in "${CHECK_ROOT}/tests"/test*.in; do
        [[ -f "${input}" ]] || continue
        cmp -s "${input%.in}.expected" "${input%.in}.out" || return 1
        count=$((count + 1))
    done
    (( count == TEST_COUNT )) || return 1
    # Confirma que test propaga un FAIL, no solamente imprime un mensaje.
    cp "${CHECK_ROOT}/tests/test001.expected" "${TEMP_DIR}/saved.expected" || return 1
    printf '%s\n' 'Resultado deliberadamente distinto para verificar la suite' > "${CHECK_ROOT}/tests/test001.expected"
    (cd "${CASE_DIR}" && timeout 15 make test)
    status=$?
    cp "${TEMP_DIR}/saved.expected" "${CHECK_ROOT}/tests/test001.expected" || return 1
    rm -f "${CASE_DIR}/test"
    (( status > 0 && status < 124 ))
}

protected_files() {
    find "${CHECK_ROOT}" -type f \
        \( -name '*.c' -o -name '*.h' -o -name Makefile -o -name '*.in' \
        -o -name '*.expected' -o -name '*.sh' -o -name '*.a' \
        -o -name evacuacion_manual -o -name evacuacion_estatica \) \
        -exec sha256sum {} + | LC_ALL=C sort
}

clean_target() {
    (( BUILT == 1 )) || return 1
    local object=""
    protected_files > "${TEMP_DIR}/protected.before"
    touch "${CASE_DIR}/clean"
    (cd "${CASE_DIR}" && timeout 15 make clean) || return 1
    [[ ! -e "${CASE_DIR}/${TARGET}" ]] || return 1
    for object in "${OBJECTS[@]}"; do
        [[ ! -e "${CASE_DIR}/${object}" && ! -e "${CASE_DIR}/${object%.o}.d" ]] || return 1
    done
    protected_files > "${TEMP_DIR}/protected.after"
    cmp -s "${TEMP_DIR}/protected.before" "${TEMP_DIR}/protected.after" || return 1
    rm -f "${CASE_DIR}/clean"
}

check_project() {
    local section="$1"
    check "[${section}] ${TARGET} se construye desde sus archivos objeto" build_case
    check "[${section}] La compilación utiliza los flags solicitados" compile_options
    check "[${section}] Se generan los archivos de dependencias" dependency_files
    check "[${section}] El programa construido supera los cuatro tests" case_matches
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio MAK   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

prepare_case code/case001 suma main.o suma.o
check '[1.1] suma se construye desde sus dos archivos objeto' build_case
check '[1.2] La compilación utiliza los flags del Makefile' compile_options
check '[1.1] suma produce el resultado esperado' case_matches
check '[1.3] Sin cambios no se recompila ni se enlaza' no_rebuild
check '[1.3] Un cambio en suma.c actualiza solamente suma.o y el ejecutable' incremental suma.c 'suma.o'
check '[1.3] clean elimina los archivos de compilación y conserva las fuentes' clean_target

prepare_case code/case002 relay_example main.o checksum.o decoder.o
check '[2.1] relay_example se construye desde sus archivos objeto' build_case
check '[2.1] La compilación utiliza los flags solicitados' compile_options
check '[2.2] Se generan los archivos de dependencias' dependency_files
check '[2.4] El ejemplo conserva su resultado original' case_matches
check '[2.3] Sin cambios no se recompila ni se enlaza' no_rebuild
check '[2.3] Un cambio en decoder.c actualiza solamente decoder.o y el ejecutable' incremental decoder.c 'decoder.o'
check '[2.3] Un cambio en decoder.h actualiza main.o, decoder.o y el ejecutable' incremental decoder.h 'main.o decoder.o'
check '[2.3] clean elimina los archivos de compilación y conserva las fuentes' clean_target

prepare_case code/case003 rebel_link main.o parser.o capacity.o priority.o report.o
check_project '3.2'
check '[3.3] test ejecuta la suite y propaga los resultados fallidos' suite_target
check '[3.3] priority.h actualiza priority.o, report.o y el ejecutable' incremental priority.h 'priority.o report.o'
check '[3.4] clean elimina los archivos de compilación y conserva fuentes y tests' clean_target

check '[3.3] tests-run.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/tests-run.sh"
check '[4] check.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/check.sh"
summary
