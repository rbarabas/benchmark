#!/usr/bin/env bash

source $(dirname $0)/settings.sh
source $(dirname $0)/common.sh

function plot_threads() {
  for T in ${THREADS}; do
      THREAD_PATH="${TARGET_DIR}/threads_${T}"
      THREAD_DATA="${THREAD_PATH}.data"
      THREAD_TPS="${THREAD_PATH}.tps"
      THREAD_QPS="${THREAD_PATH}.qps"
      THREAD_RWO="${THREAD_PATH}.rwo"
      THREAD_LAT="${THREAD_PATH}.lat"
      THREAD_PLOT="${THREAD_PATH}.gnuplot"
      TPS_PLOT="${THREAD_PATH}_tps.png"
      QPS_PLOT="${THREAD_PATH}_qps.png"
      RWO_PLOT="${THREAD_PATH}_rwo.png"
      LAT_PLOT="${THREAD_PATH}_lat.png"
      THREAD_PNG="${THREAD_PATH}.png"
      if [ ! -f ${THREAD_DATA} ]; then
          error 2 "missing data: ${THREAD_DATA}"
          continue
      fi
      cat "${THREAD_DATA}" | awk '{if ($0 ~ /thds/){ print $2, $7 }}' | tr -d ')s' | tr '/' ' ' > ${THREAD_TPS}
      cat "${THREAD_DATA}" | awk '{if ($0 ~ /thds/){ print $2, $9 }}' | tr -d ')s' | tr '/' ' ' > ${THREAD_QPS}
      cat "${THREAD_DATA}" | awk '{if ($0 ~ /thds/){ print $2, $11 }}' | tr -d ')s' | tr '/' ' '> ${THREAD_RWO}
      cat "${THREAD_DATA}" | awk '{if ($0 ~ /thds/){ print $2, $14 }}' | tr -d ')s' | tr '/' ' '> ${THREAD_LAT}
      cat << PLOT > ${THREAD_PLOT}
set xdata time
set timefmt "%s"
set xlabel "Time"
set ylabel "QPS"
plot "${THREAD_TPS}" using 1:2 title "TPS" with lines,     \
     "${THREAD_QPS}" using 1:2 title "QPS" with lines,     \
     "${THREAD_RWO}" using 1:2 title "R/W/O" with lines,   \
     "${THREAD_LAT}" using 1:2 title "Latency" with lines
set terminal png font "/Library/Fonts/Arial Unicode.ttf" 14
set output "${THREAD_PNG}"
PLOT
      gnuplot -persist ${THREAD_PLOT}
  done
}

while getopts "d:" opt; do
  case ${opt} in
    d) TARGET_DIR="${OPTARG}" ;;
  esac
done

[ -z "${TARGET_DIR}" ] && error 1 "please specify data directory"

plot_threads

