#!/usr/bin/env bash

THREADS="1 2 4 8 16 32 64"
NTABLES=100
NROWS=5000000 
DB_TYPE=pgsql
DB_USER=sbtest
DB_PASS=sbtest
DB_NAME=sbtest
DURATION_SECONDS=600
REPORTING_SECONDS=1
TEST_TYPE=/usr/share/sysbench/oltp_read_write.lua

function initdb() {
  sysbench  --db-driver=${DB_TYPE} \
            --table-size=${NROWS} \
            --tables=${NTABLES} \
            --threads=${T}  \
            --${DB_TYPE}-host=${TARGET_HOST} \
            --${DB_TYPE}-port=${TARGET_PORT}  \
            --${DB_TYPE}-user=${DB_USER}  \
            --${DB_TYPE}-password=${DB_PASS}  \
            --${DB_TYPE}-db=${DB_NAME}  \
            --time=${DURATION_SECONDS} \
            ${TEST_TYPE} \
            prepare
}

function benchmarkdb() {
  for T in $THREADS; do
    # Setup FD to capture output
    exec 3>${TARGET_DIR}/threads_${T}.out
    exec 1>&3
    exec 2>&3
  
    echo "*** Benchmarking with ${T} threads ***"
    sysbench  --db-driver=${DB_TYPE} \
              --table-size=${NROWS} \
              --tables=${NTABLES} \
              --threads=${T} \
              --${DB_TYPE}-host=${TARGET_HOST} \
              --${DB_TYPE}-port=${TARGET_PORT}  \
              --${DB_TYPE}-user=${DB_USER}  \
              --${DB_TYPE}-password=${DB_PASS}  \
              --${DB_TYPE}-db=${DB_NAME}  \
              --time=${DURATION_SECONDS} \
              --report-interval=${REPORTING_SECONDS} \
              --histogram=on \
              ${TEST_TYPE} \
              run
 
    # Close FD
    exec 3>&-
  done
}

function cleandb() {
  echo sysbench  --db-driver=${DB_TYPE} \
            --table-size=${NROWS} \
            --tables=${NTABLES} \
            --threads=${T}  \
            --${DB_TYPE}-host=${TARGET_HOST} \
            --${DB_TYPE}-port=${TARGET_PORT}  \
            --${DB_TYPE}-user=${DB_USER}  \
            --${DB_TYPE}-password=${DB_PASS}  \
            --${DB_TYPE}-db=${DB_NAME}  \
            --time=${DURATION_SECONDS} \
            ${TEST_TYPE} \
            cleanup
}

function help() {
  echo "$0 -c init|run|clean -h HOST [-p PORT] [-d LOGDIR]"
  exit 1
}

function error() {
  ret=$1
  shift
  echo $*
  exit $ret
}

while getopts "c:h:p:d:" opt; do
  case ${opt} in
    c) COMMAND="${OPTARG}" ;;
    h) TARGET_HOST="${OPTARG}" ;;
    p) TARGET_PORT="${OPTARG}" ;;
    d) TARGET_DIR="${OPTARG}" ;;
  esac
done

# Mandatory arguments check
if [ -z ${TARGET_HOST} ] || [ -z "${COMMAND}" ]; then
  help
fi

# Defaults
[ -z "${TARGET_PORT}" ] && TARGET_PORT=5432
[ -z "${TARGET_DIR}" ] && TARGET_DIR=./

# Check if logging directory exist
[ ! -d ${TARGET_DIR} ] && error 2 "incorrect target for log directory: ${TARGET_DIR}"

if [ "${COMMAND}" = "init" ]; then
  echo " [*] Initializing test db on ${TARGET_HOST}" 
  initdb ${TARGET_HOST} ${TARGET_PORT}
elif [ "${COMMAND}" = "clean" ]; then
  echo " [*] Removing test db from ${TARGET_HOST}" 
  cleandb ${TARGET_HOST} ${TARGET_PORT}
elif [ "${COMMAND}" = "run" ]; then
  echo " [*] Running benchmark on ${TARGET_HOST}" 
  benchmarkdb ${TARGET_HOST} ${TARGET_PORT}
else
  help
fi

