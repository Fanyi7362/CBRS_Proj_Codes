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

def random_phase(min, max):
    imin = int(min / 22.5)
    imax = int(max / 22.5)
    irandom = random.randint(imin, imax)
    return irandom * 22.5

def phase_to_byte(phase_value):
    # Convert the phase value to an index
    phase_ind = int(phase_value / 22.5)

    # Convert the phase value to a binary value with padding
    # Add padding 2 bits at the start and end
    phase_byte = (phase_ind & 0b1111) << 2

    return phase_byte


def send_phase_values_to_device(arduino_device):
    # Send preamble
    arduino_device.write(Serial_PREAMBLE)
    
    # Generate 6 random phase values and send
    for ii in range(6):
        phase_value = random_phase(0, 337.5)  # Assuming you want phase values from 0 to 360
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
        
    time.sleep(0.25)

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
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    print(f"PC1 start connecting to PC2!")
    client_socket.connect((PC2_IP_ADDRESS, PC2_PORT))
    client_socket.settimeout(Socket_TIMEOUT)  # timeout for socket to allow non-blocking behavior
    print(f"Connection success!")
    
    arduinos = [serial.Serial(link, BAUD_RATE, timeout=1) for link in ARDUINO_LINKS]

    try:
        for _ in range(128):  # Repeat 128 times
            # Send phases to all Arduinos
            for arduino_device in arduinos:
                arduino_device.flushInput()
                arduino_device.flushOutput()
                if not send_phase_values_to_device(arduino_device):
                    print(f"Did not receive expected ACK from Arduino. Stopping!")
                    return

            # Send Socket_LOG to PC2 and wait for ACK
            client_socket.sendall(Socket_LOG)
            if wait_for_ack(client_socket, Socket_ACK, Socket_TIMEOUT):
                print(f"Received ACK from PC2!")
            else:
                print(f"Did not receive expected ACK from PC2. Stopping!")
                break                
                
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
