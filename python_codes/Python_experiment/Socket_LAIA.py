import socket
import serial
import time
import random
import itertools
import numpy as np

# Parameters
ARDUINO_LINKS = [
    '/dev/arduinoMKR1010_1', '/dev/arduinoMKR1010_2', '/dev/arduinoMKR1010_3',
    '/dev/arduinoMKR1010_4', '/dev/arduinoMKR1010_5', '/dev/arduinoMKR1010_6',
    '/dev/arduinoMKR1010_7', '/dev/arduinoMKR1010_8'
]
ARDUINO_LINKS_TEST = [
    '/dev/arduinoMKR1010_2', '/dev/arduinoMKR1010_6'
]
PC2_IP_ADDRESS = '192.168.0.2'
PC2_PORT = 12345
Socket_LOG = b'\xAA\xAA'
Socket_ACK = b'\xBB\xBB'
Socket_END = b'\xCC\xCC'
Serial_PREAMBLE = b'\xAA\xAA'
Serial_ACK_SUCCESS = b'\xFF'
Serial_ACK_ERROR1 = b'\xAA'
Serial_ACK_ERROR2 = b'\xBB'
Serial_ACK_ERROR3 = b'\xCC'
BAUD_RATE = 460800
Socket_TIMEOUT = 45
Socket_TIMEOUT_SHORT = 10
Serial_TIMEOUT = 10
N_phases_per_device = 6

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print(f"PC1 start connecting to PC2!")
client_socket.connect((PC2_IP_ADDRESS, PC2_PORT))
client_socket.settimeout(Socket_TIMEOUT)
print(f"Connection success!")
arduinos = [serial.Serial(link, BAUD_RATE, timeout=1) for link in ARDUINO_LINKS]

def random_phase(min, max, n_bits):
    # Validate n_bits input
    if n_bits not in [1, 2, 3, 4]:
        raise ValueError("n_bits should be one of [1, 2, 3, 4]")

    # Map n_bits to the phase granularity
    bit_to_angle = {1: 180, 2: 90, 3: 45, 4: 22.5}
    granularity = bit_to_angle[n_bits]

    imin = int(min / granularity)
    imax = int(max / granularity)
    
    irandom = random.randint(imin, imax)
    return irandom * granularity

def generate_all_phases(n_bits):
    """Generates all possible phase values for a given n_bits."""
    bit_to_angle = {1: 180, 2: 90, 3: 45, 4: 22.5}
    granularity = bit_to_angle[n_bits]
    max_angle = 360
    return list(np.arange(0, max_angle, granularity))

def phase_to_byte(phase_value):
    # Convert the phase value to an index
    phase_ind = int(phase_value / 22.5)

    # Convert the phase value to a binary value with padding
    # Add padding 2 bits at the start and end
    phase_byte = (phase_ind & 0b1111) << 2

    return phase_byte


def send_phase_values_to_device(arduino_device, phases):
    # Send preamble
    arduino_device.write(Serial_PREAMBLE)
    
    for phase_value in phases:
        print(phase_value)
        byte_to_send = phase_to_byte(phase_value)
        arduino_device.write(bytearray([byte_to_send]))

    start_time = time.time()
    while True:
        ack = arduino_device.read(1)  # Assuming the ACK is 1 byte long
        if ack == Serial_ACK_SUCCESS:
            print("Arduino %s Success!" % arduino_device.port)
            break
        elif ack == Serial_ACK_ERROR1:
            print("Arduino %s Error 1!" % arduino_device.port)
            break
        elif ack == Serial_ACK_ERROR2:
            print("Arduino %s Error 2!" % arduino_device.port)
            break  
        elif ack == Serial_ACK_ERROR3:
            print("Arduino %s Error 3!" % arduino_device.port)
            break                        

        current_time = time.time()
        if (current_time - start_time) > Serial_TIMEOUT:
            print("Timeout while waiting for acknowledgement")
            return False  # Timed out before receiving expected ACK
        
    time.sleep(0.1)

    return True

def wait_for_ack(socket, ack, timeout):
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            data = socket.recv(len(ack))
            if data == ack:
                return True
        except socket.timeout:
            continue
    return False

def wait_for_rate(socket, timeout):
    start_time = time.time()
    buffer_size = 1024  # Adjust this value if needed
    received_float = -100.0
    while time.time() - start_time < timeout:
        try:
            data = socket.recv(buffer_size).decode("utf-8").strip()
            try:
                received_float = float(data)
                print(f"Received mean power: {received_float}")
                return received_float
            except ValueError:
                continue  # Received data isn't a valid float
        except socket.timeout:
            continue
    return received_float  

def get_feedback():
    # Send Socket_LOG to PC2 and wait for ACK
    client_socket.sendall(Socket_LOG)
    feedback = -100.0
    if wait_for_ack(client_socket, Socket_ACK, Socket_TIMEOUT_SHORT):
        print(f"Received ACK from PC2!")
        feedback = wait_for_rate(client_socket, Socket_TIMEOUT_SHORT)
    else:
        print(f"Did not receive expected ACK from PC2. Stopping!")
        return feedback   

    return feedback


def main():
    print(f"Main Starts!")
    
    # this list starts from 0, so to traverse arduino3, use [2]
    traverse_list = list(range(8))
    n_bits = 4
    n_traverseEle = 1 # smaller than 6, n_traverseEle is the number of elements per traverse group
    n_iteration = 1

    # Create phase_all array, size 8*6
    phase_all = [[0 for _ in range(N_phases_per_device)] for _ in range(len(ARDUINO_LINKS))]
    all_possible_phases = generate_all_phases(n_bits)

    # initialize all devices to zero phase
    for i, arduino_device in enumerate(arduinos):
        arduino_device.flushInput()
        arduino_device.flushOutput()
        if not send_phase_values_to_device(arduino_device, phase_all[i]):
            print(f"Did not receive expected ACK from Arduino. Stopping!")
            return

    try:
        # run the same searching for n_iteration times
        for ii in range(n_iteration):
            # Create a matrix to store the rates
            num_cases = len(all_possible_phases)**n_traverseEle
            rate_matrix = np.zeros((len(traverse_list) * N_phases_per_device//n_traverseEle, num_cases))

            # 8 devices to traverse
            for device_to_traverse in traverse_list:
                # 6 elements per device
                N_groups = N_phases_per_device//n_traverseEle
                for group_to_traverse in range(N_groups):
                    max_rate=-100.0
                    max_rate_phase = (0,) * n_traverseEle
                    start_ele = group_to_traverse*n_traverseEle

                    for idx, comb in enumerate(itertools.product(all_possible_phases, repeat=n_traverseEle)):
                        for comb_index, phase_val in enumerate(comb):
                            phase_all[device_to_traverse][start_ele + comb_index] = phase_val

                        arduino_device = arduinos[device_to_traverse]
                        arduino_device.flushInput()
                        arduino_device.flushOutput()
                        if not send_phase_values_to_device(arduino_device, phase_all[device_to_traverse]):
                            print(f"Did not receive expected ACK from Arduino. Stopping!")
                            return

                        # Send Socket_LOG to PC2 and wait for ACK
                        rate = get_feedback()
                        rate_matrix[device_to_traverse * N_groups + group_to_traverse, idx] = rate

                        if rate > max_rate:
                            max_rate = rate
                            max_rate_phase = comb
                            print(f"max_rate updated to: {max_rate}")

                    for comb_index, phase_val in enumerate(max_rate_phase):
                        print(f"max_rate_phase: {max_rate_phase}, for device: {device_to_traverse}, element: {group_to_traverse}")
                        phase_all[device_to_traverse][start_ele + comb_index] = phase_val
            
            # Save the rate_matrix to file
            np.savetxt(f"/data/rate_history_iter_{ii}.txt", rate_matrix, delimiter=",", fmt="%0.4f")            


    except KeyboardInterrupt:
        print("Interrupted!")

    finally:
        client_socket.sendall(Socket_END)
        print("Sent Socket_END to PC2.")
        client_socket.close()

        for arduino_device in arduinos:
            arduino_device.close()

if __name__ == '__main__':
    main()
