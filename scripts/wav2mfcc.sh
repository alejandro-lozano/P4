#!/bin/bash

## \file
## Fichero para calcular los coeficientes cepstrales en escala Mel (MFCC)

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 5 ]]; then
   echo "$0  mfcc_order filterbank_order sampling_freq input.wav output.mfcc"
   exit 1
fi

mfcc_order=$1
filterbank_order=$2
sampling_freq=$3
inputfile=$4
outputfile=$5

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   MFCC="mfcc"
fi

# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
$MFCC -l 240 -m $mfcc_order -n $filterbank_order -s $sampling_freq  > $base.mfcc

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=$($X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";') 

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile

exit