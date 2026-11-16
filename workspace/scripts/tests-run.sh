#!/usr/bin/env bash

set -u

PROGRAM="${1:-}"
TARGET_DIR="${2:-}"

total=0
passed=0
failed=0
errors=0

if [ -z "$PROGRAM" ] || [ -z "$TARGET_DIR" ]; then
  echo "Uso: $0 <RUTA_AL_EJECUTABLE> <DIRECTORIO_DE_TESTS>"
  exit 2
fi

if [ ! -x "$PROGRAM" ]; then
  echo "ERRO: No se encontró un ejecutable en $PROGRAM"
  exit 2
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "ERRO: La carpeta no existe: $TARGET_DIR"
  exit 2
fi

printf '%s\n' '========================================='
printf '%s\n' '==            Test cases               =='
printf '%s\n' '========================================='
printf '\n== Resultados ===========================\n\n'

set_has_tests=0

for input_file in "$TARGET_DIR"/test*.in; do
  [ -f "$input_file" ] || continue
  set_has_tests=1

  test_name="$(basename "$input_file" .in)"
  expected_file="$TARGET_DIR/$test_name.expected"
  output_file="$TARGET_DIR/$test_name.out"
  error_file="$TARGET_DIR/$test_name.err"
  diff_file="$TARGET_DIR/$test_name.diff"

  total=$((total + 1))

  if [ ! -f "$expected_file" ]; then
    echo "ERRO:  $test_name"
    errors=$((errors + 1))
    continue
  fi

  "$PROGRAM" < "$input_file" > "$output_file" 2> "$error_file"
  program_status=$?

  if [ "$program_status" -ne 0 ]; then
    echo "ERRO:  $test_name"
    errors=$((errors + 1))
    continue
  fi

  if diff -u "$expected_file" "$output_file" > "$diff_file"; then
    echo "PASS:  $test_name"
    rm -f "$diff_file" "$error_file"
    passed=$((passed + 1))
  else
    echo "FAIL:  $test_name"
    failed=$((failed + 1))
  fi
done

if [ "$set_has_tests" -eq 0 ]; then
  echo "ERRO:  No se encontraron archivos testNNN.in en $TARGET_DIR"
  errors=$((errors + 1))
fi

printf '\n== Resumen ===============================\n\n'
count_width=${#total}
printf '%-20s %*d\n' 'Test cases:' "$count_width" "$total"
printf '%-20s %*d\n' 'Pruebas exitosas:' "$count_width" "$passed"
printf '%-20s %*d\n' 'Pruebas fallidas:' "$count_width" "$failed"
printf '%-20s %*d\n\n' 'Errores:' "$count_width" "$errors"

if [ "$failed" -eq 0 ] && [ "$errors" -eq 0 ]; then
  exit 0
fi

exit 1
