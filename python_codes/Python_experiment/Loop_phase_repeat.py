import socket
import serial
import time
import random

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
Serial_TIMEOUT = 10

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

def main():
    print(f"Main Starts!")
    
    arduinos = [serial.Serial(link, BAUD_RATE, timeout=1) for link in ARDUINO_LINKS]
    
    # Create phase_all array
    # an 8x6 matrix where every element is initialized to zero
    phase_all = [[0 for _ in range(6)] for _ in range(len(ARDUINO_LINKS))]
    try:
        for ii in range(256):  # Repeat 128 times
            if ii%2==0:
                phase_min = 0
                phase_max = 0
            elif ii%2==1:
                phase_min = 180
                phase_max = 180

            # Generate phases for all Arduinos
            for i, arduino_device in enumerate(arduinos):
                for j in range(6):
                    phase_all[i][j] = random_phase(phase_min, phase_max, 2)

            # Send phases to all Arduinos
            for i, arduino_device in enumerate(arduinos):
                arduino_device.flushInput()
                arduino_device.flushOutput()
                if not send_phase_values_to_device(arduino_device, phase_all[i]):
                    print(f"Did not receive expected ACK from Arduino. Stopping!")
                    return            
                
            time.sleep(0.040)
                
    except KeyboardInterrupt:
        print("Interrupted!")

    finally:
        for arduino_device in arduinos:
            arduino_device.close()

if __name__ == '__main__':
    main()
