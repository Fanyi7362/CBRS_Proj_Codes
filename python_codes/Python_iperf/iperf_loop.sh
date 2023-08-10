#!/bin/bash

# Infinite loop
while true; do
    # Start iperf3 client with 200Mbits/s bandwidth for 4 seconds
    iperf3 -u -c 10.9.27.41 -p 5201 -R -t 4 -i 1 -b 400M

    # Sleep for 1 second
    sleep 1
done
