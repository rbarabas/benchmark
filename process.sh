#!/usr/bin/env bash

source $(dirname $0)/settings.sh
source $(dirname $0)/common.sh

# Data mapping in format description:column (awk output column number)
DATA_MAP="TPS:7 QPS:9 latency:14 reads:11:2 writes:11:3 other:11:4"

function process() {
  for d in ${DATA_MAP}; do
    dtyp=$(echo ${d} | cut -d: -f1)
    dcol=$(echo ${d} | cut -d: -f2)
    scol=$(echo ${d} | cut -d: -f3)
    for i in ${THREADS}; do
      path="${TARGET_DIR}/threads_${i}"
      dout="${path}.${dtyp}"
      if [ -z "$scol" ]; then
        cat "${path}.data"                                  \
        | awk "{if (\$0 ~ /thds/){ print \$2, \$${dcol} }}" \
        | tr -d ')s' | tr '/' ' ' > ${dout}
      else
        cat "${path}.data"                                  \
        | awk "{if (\$0 ~ /thds/){ print \$2, \$${dcol} }}" \
        | tr -d ')s' | tr '/' ' '                           \
        | awk "{print \$1, \$${scol}}" > ${dout}
      fi
    done
  done
 }

function plot() {
  plotfile="${TARGET_DIR}/benchmark.gnuplot"
  pngfile="${TARGET_DIR}/benchmark.png"
  plotcmds=""
  for d in ${DATA_MAP}; do
    plotcmd=""
    dtyp=$(echo ${d} | cut -d: -f1)
    dcol=$(echo ${d} | cut -d: -f2)
    for i in ${THREADS}; do
      path="${TARGET_DIR}/threads_${i}"
      datafile="${path}.${dtyp}"
      TYPE_DATA="${TARGET_DIR}/threads_${i}.${dtyp}"
      thiscmd="\"${datafile}\" using 1:2 title \"${i} thread\" with lines"
      if [ -z "${plotcmd}" ]; then
        plotcmd=$(echo -e "set ylabel \"${dtyp}\"\nplot ${thiscmd}")
      else
        plotcmd=$(echo -e "${plotcmd}, ${thiscmd}")
      fi
    done
    plotcmds=$(echo -e "${plotcmds}\n${plotcmd}")
  done

  cat << PLOT > ${plotfile}
set xdata time
set timefmt "%s"
set term png size 1920,1080
set output "${pngfile}"
set multiplot layout 2,3 columnsfirst title "Database Benchmark Results"
set format x '%s'
${plotcmds}
unset multiplot
PLOT

  gnuplot -persist ${plotfile}
}

while getopts "d:" opt; do
  case ${opt} in
    d) TARGET_DIR="${OPTARG}" ;;
  esac
done

[ -z "${TARGET_DIR}" ] && error 1 "please specify data directory"

process
plot

