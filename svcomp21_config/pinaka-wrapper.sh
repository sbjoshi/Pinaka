#!/bin/bash

TOOL_BINARY=pinaka
TOOL_NAME=Pinaka

# Function to run the tool
run()
{
  programhash=$(sha256sum $BENCHMARK | awk '{print $1}')
  # property=$(<$PROP_FILE)
  ./$TOOL_BINARY $MODE $BIT_WIDTH --object-bits $OBJECT_BITS --graphml-witness $WITNESS_FILE --hashval $programhash --property-file $PROP_FILE $BENCHMARK
}

BIT_WIDTH="--64"
BENCHMARK=""
PROP_FILE=""
WITNESS_FILE=""
MODE="--partial-incremental"
OBJECT_BITS="11"

while [ -n "$1" ] ; do
  case "$1" in
    --32|--64) BIT_WIDTH="$1" ; shift 1 ;;
    --propertyfile) PROP_FILE="$2" ; echo "PropertyFile Found" ; shift 2 ;;
    --graphml-witness) WITNESS_FILE="$2" ; shift 2 ;;
    --version) echo "0.1"; exit 0 ;;
    *) BENCHMARK="$1" ; echo "BenchMark Found" ; shift 1 ;;
  esac
done

if [ -z "$BENCHMARK" ] ; then
  echo "Missing benchmark or property file"
  exit 1
fi

if [ ! -s "$BENCHMARK" ] ; then
  echo "Empty benchmark or property file"
  exit 1
fi

if [ -z "$PROP_FILE" ] ; then
  echo "Missing property file"
  exit 1
fi

if [ ! -s "$PROP_FILE" ] ; then
  echo "Empty property file"
  exit 1
fi
# LOG_DIR="${TOOL_NAME}_Results/"
# mkdir $LOG_DIR
run