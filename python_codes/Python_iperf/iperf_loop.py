#!/usr/bin/env python3

import subprocess
import time
from datetime import datetime

data_rates = []
lost_data = []
total_data = []

def run_iperf():
    # Call iperf3 command
    result = subprocess.run(["iperf3", "-u", "-c", "10.9.27.41", "-p", "5201", "-R", "-t", "1", "-b", "400M"], capture_output=True, text=True)

    # Parse output for data rate and Lost/Total datagrams
    for line in result.stdout.splitlines():
        if "receiver" in line:  
            data_rate = float(line.split()[6])
            lost, total = map(int, line.split()[10].split('/'))
            return data_rate, lost, total

    return None, None, None

start_time = time.time()

while True:
    rate, lost, total = run_iperf()
    if rate is not None:
        data_rates.append(rate)
    if lost is not None and total is not None:
        lost_data.append(lost)
        total_data.append(total)
    
    # Sleep for 0.25s
    time.sleep(0.25)

    # If 12.5 seconds have passed
    if time.time() - start_time >= 12.5:
        average_rate = sum(data_rates) / len(data_rates)
        total_lost = sum(lost_data)
        total_packets = sum(total_data)

        # Current timestamp in desired format
        timestamp = datetime.now().strftime('%m-%d-%H:%M:%S')

        # Log the average_rate, aggregated Lost/Total, and the timestamp to a file
        with open('iperf3_log.txt', 'a') as f:
            f.write(f"{timestamp}, {average_rate:6.2f} Mbits/sec, Lost/Total: {total_lost:5}/{total_packets:5}\n")

        # Reset the data_rates, lost_data, and total_data arrays and the timer
        data_rates = []
        lost_data = []
        total_data = []
        start_time = time.time()
