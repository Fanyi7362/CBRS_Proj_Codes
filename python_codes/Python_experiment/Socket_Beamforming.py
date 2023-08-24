import numpy as np
import time
import socket
import serial

# Arduino and Socket Parameters
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
N_devices = 8
N_phases_per_device = 6

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print(f"PC1 start connecting to PC2!")
client_socket.connect((PC2_IP_ADDRESS, PC2_PORT))
client_socket.settimeout(Socket_TIMEOUT)  # timeout for socket to allow non-blocking behavior
print(f"Connection success!")
arduinos = [serial.Serial(link, BAUD_RATE, timeout=1) for link in ARDUINO_LINKS]


# Beamforming Parameters
N_ELEMENTS = 48
INIT_STEP_SIZE = 90
STEP_SIZE_MIN = 22.5
STEP_SIZE_MAX = 135
FEEDBACK_WINDOW = 500

N_EXPLORE = 4
EXPLORE_STEP_SIZE = 22.5
N_STEP_ADJUST_THRESH = 10
DATA_RATE_MAX = 2100
N_STEP_ADJUST_MAX = 20


class NgscopeBeamformingState:
    def __init__(self, step_size=INIT_STEP_SIZE, max_rate=-100.0):
        self.step_size = step_size
        self.max_rate = max_rate # We call it rate but it is actually the RSSI
        self.phase_array = np.zeros(N_ELEMENTS)


def random_phase(min_val, max_val, n_bits):
    # Validate n_bits input
    if n_bits not in [1, 2, 3, 4]:
        raise ValueError("n_bits should be one of [1, 2, 3, 4]")

    # Map n_bits to the phase granularity
    bit_to_angle = {1: 180, 2: 90, 3: 45, 4: 22.5}
    granularity = bit_to_angle[n_bits]

    imin = int(min_val / granularity)
    imax = int(max_val / granularity)
    
    irandom = np.random.randint(imin, imax + 1)  # numpy's randint is inclusive for the start and exclusive for the stop
    return irandom * granularity


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
        # print(phase_value)
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

def write_phase_to_arduino(state):
    for i, arduino_device in enumerate(arduinos):
        arduino_device.flushInput()
        arduino_device.flushOutput()
        start = i * N_phases_per_device
        end = start + N_phases_per_device
        if not send_phase_values_to_device(arduino_device, state.phase_array[start:end]):
            print(f"Did not receive expected ACK from Arduino. Stopping!")
            return False
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

def get_feedback(state):
    # Send Socket_LOG to PC2 and wait for ACK
    client_socket.sendall(Socket_LOG)
    new_rate = -100.0
    feedback = -1
    if wait_for_ack(client_socket, Socket_ACK, Socket_TIMEOUT_SHORT):
        print(f"Received ACK from PC2!")
        new_rate = wait_for_rate(client_socket, Socket_TIMEOUT_SHORT)
        if new_rate > state.max_rate:
            state.max_rate = new_rate
            feedback = 1
    else:
        print(f"Did not receive expected ACK from PC2. Stopping!")
        return feedback   

    return feedback


def adjust_stepsize(n_explore_hist, n_random_guess, bf_st):
    sum_explore = sum(n_explore_hist[:n_random_guess])
    
    if sum_explore / n_random_guess > 1 and bf_st.step_size < STEP_SIZE_MAX:
        bf_st.step_size += 22.5
    elif sum_explore / n_random_guess <= 1 and bf_st.step_size > STEP_SIZE_MIN:
        bf_st.step_size -= 22.5



def beamforming_algorithm():
    # Step 1: Initialization
    delay = 10  # 10 seconds

    # Initialize the ngscope_beamforming_state_t struct
    bf_state = NgscopeBeamformingState()

    phase_change = np.zeros(N_ELEMENTS)
    n_random_guess = 0
    n_step_adjust = 0
    n_explore = 0
    n_explore_hist = np.zeros(N_STEP_ADJUST_THRESH + 1)
    n_bits = 4

    feedback = 0
    try:
        while True:
            # Step 2: Random Guess
            for i in range(N_ELEMENTS):
                phase_change[i] = random_phase(-bf_state.step_size, bf_state.step_size, n_bits)
                bf_state.phase_array[i] += phase_change[i]
                bf_state.phase_array[i] %= 360.0

            if not write_phase_to_arduino(bf_state):
                print("Failed to send phase values to Arduino. Stopping!")
                break
            feedback = get_feedback(bf_state)

            if feedback < 0:
                for i in range(N_ELEMENTS):
                    phase_change[i] *= -1
                    bf_state.phase_array[i] += 2 * phase_change[i]
                    bf_state.phase_array[i] %= 360.0

                if not write_phase_to_arduino(bf_state):
                    print("Failed to send phase values to Arduino. Stopping!")
                    break
                feedback = get_feedback(bf_state)

                if feedback < 0:
                    for i in range(N_ELEMENTS):
                        bf_state.phase_array[i] -= phase_change[i]
                        bf_state.phase_array[i] %= 360.0

                    if not write_phase_to_arduino(bf_state):
                        print("Failed to send phase values to Arduino. Stopping!")
                        break
                    print(f"Feedback is still negative! n_random_guess:{n_random_guess} n_explore:{n_explore}")
                    n_explore_hist[n_random_guess] = n_explore
                    n_explore = 0
                    n_random_guess += 1

            # Step 3: Explore
            if feedback > 0:
                print("Explore started!");
                n_explore += 1
                while n_explore <= N_EXPLORE:
                    for i in range(N_ELEMENTS):
                        phase_change[i] = (1 if phase_change[i] > 0 else -1) * EXPLORE_STEP_SIZE
                        bf_state.phase_array[i] += phase_change[i]
                        bf_state.phase_array[i] %= 360.0

                    if not write_phase_to_arduino(bf_state):
                        print("Failed to send phase values to Arduino. Stopping!")
                        break
                    feedback = get_feedback(bf_state)
                    if feedback < 0:
                        for i in range(N_ELEMENTS):
                            bf_state.phase_array[i] -= phase_change[i]
                            bf_state.phase_array[i] %= 360.0

                        if not write_phase_to_arduino(bf_state):
                            print("Failed to send phase values to Arduino. Stopping!")
                            break
                        break

                    n_explore += 1
                print("Explore finished! n_random_guess:{n_random_guess} n_explore:{n_explore}")
                n_explore_hist[n_random_guess] = n_explore
                n_explore = 0
                n_random_guess += 1

            # Step 4: Step Size Adjustment
            if n_random_guess >= N_STEP_ADJUST_THRESH:
                adjust_stepsize(n_explore_hist, n_random_guess, bf_state)
                n_step_adjust += 1
                n_random_guess = 0

            # Step 5: Stop Condition
            if bf_state.max_rate >= DATA_RATE_MAX or n_step_adjust >= N_STEP_ADJUST_MAX:
                time.sleep(delay)

    except KeyboardInterrupt:
        print("Interrupted!")

    finally:
        client_socket.sendall(Socket_END)
        print("Sent Socket_END to PC2.")

        client_socket.close()
        for arduino_device in arduinos:
            arduino_device.close()

    return None


# Test the algorithm
beamforming_algorithm()