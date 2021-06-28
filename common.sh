#!/usr/bin/env bash

function error() {
  ret=$1
  shift
  echo $*
  exit $ret
}

