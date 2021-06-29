#!/usr/bin/env bash

source "$(dirname $0)/settings.sh"
source $(dirname $0)/common.sh

function preparedb() {
  MAXTHREADS=$(echo ${THREADS} | awk '{ print $NF }')
  sysbench  --db-driver=${DB_TYPE} \
            --table-size=${NROWS} \
            --tables=${NTABLES} \
            --threads=${MAXTHREADS} \
            --${DB_TYPE}-host=${TARGET_HOST} \
            --${DB_TYPE}-port=${TARGET_PORT} \
            --${DB_TYPE}-user=${DB_USER} \
            --${DB_TYPE}-password=${DB_PASS} \
            --${DB_TYPE}-db=${DB_NAME} \
            --time=${DURATION_SECONDS} \
            ${TEST_TYPE} \
            prepare
}

function benchmarkdb() {
  for T in $THREADS; do
    # Setup FD to capture output
    exec 3>${TARGET_DIR}/threads_${T}.data
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
  MAXTHREADS=$(echo ${THREADS} | awk '{ print $NF }')
  sysbench  --db-driver=${DB_TYPE} \
            --table-size=${NROWS} \
            --tables=${NTABLES} \
            --threads=${MAXTHREADS} \
            --${DB_TYPE}-host=${TARGET_HOST} \
            --${DB_TYPE}-port=${TARGET_PORT} \
            --${DB_TYPE}-user=${DB_USER} \
            --${DB_TYPE}-password=${DB_PASS} \
            --${DB_TYPE}-db=${DB_NAME} \
            --time=${DURATION_SECONDS} \
            ${TEST_TYPE} \
            cleanup
}

function help() {
  echo "$0 -c prepare|run|clean -h HOST [-p PORT] [-d LOGDIR]"
  exit 1
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

if [ "${COMMAND}" = "prepare" ]; then
  echo " [*] Preparing test db on ${TARGET_HOST}" 
  preparedb ${TARGET_HOST} ${TARGET_PORT}
elif [ "${COMMAND}" = "clean" ]; then
  echo " [*] Removing test db from ${TARGET_HOST}" 
  cleandb ${TARGET_HOST} ${TARGET_PORT}
elif [ "${COMMAND}" = "run" ]; then
  echo " [*] Running benchmark on ${TARGET_HOST}" 
  benchmarkdb ${TARGET_HOST} ${TARGET_PORT}
else
  help
fi

