#!/bin/bash

sleep 10
# Loop through frequencies
for freq in $(seq 3550e6 5e6 3700e6); do
  # Start the RX measurement on PC2 using SSH
  ssh pc6228@192.168.0.2 "timeout --signal=INT 15s ~/fanyi/LTEScope_CSI/build/lib/examples/cell_measurement -f $freq -n 500" &
  # Let's assume it takes a very short time for PC2's script to initiate
  
  # Start the TX on PC1
  ~/fanyi/NG-Scope/build/lib/examples/pdsch_enodeb -f $freq -n 500 -p 25 -a "addr=192.168.10.5"
  
  # Wait for both processes to complete (given they run for approximately the same time)
  wait

  # delay 1s
  sleep 1
done
