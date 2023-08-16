import socket
from pyfirmata import Arduino, util
import time

# Parameters
ARDUINO_LINKS = [
    '/dev/arduinoMKR1010_1', '/dev/arduinoMKR1010_2', '/dev/arduinoMKR1010_3', 
    '/dev/arduinoMKR1010_4', '/dev/arduinoMKR1010_5', '/dev/arduinoMKR1010_6', 
    '/dev/arduinoMKR1010_7', '/dev/arduinoMKR1010_8'
]
PC2_IP_ADDRESS = '192.168.0.2'
PC2_PORT = 12345
PREAMBLE = b'\xAA\xAA'
ACK = b'\xBB\xBB'
TIMEOUT = 45  # Adjusted to 20 seconds

arduinos = [Arduino(link) for link in ARDUINO_LINKS]
pins = [board.get_pin('d:13:o') for board in arduinos]

def set_pins_from_binary(binary_str):
    for idx, char in enumerate(binary_str):
        state = int(char)
        pins[idx].write(state)
        time.sleep(0.5)

def wait_for_ack(socket, timeout):
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            data = socket.recv(len(ACK))
            print(f"==============ACK Received==============")
            if data == ACK:
                return True
        except socket.timeout:
            print(f"===============TIMEOUT================")
            continue
    return False

def main():
    print(f"Main Starts!")
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    print(f"PC1 start connecting to PC2!")
    client_socket.connect((PC2_IP_ADDRESS, PC2_PORT))
    client_socket.settimeout(TIMEOUT)  # timeout for socket to allow non-blocking behavior

    print(f"Connection success!")
    try:
        for i in range(256):  # 2^8 combinations
            # a = 0 if i % 2 == 1 else 255
            binary_str = format(i, '08b')
            set_pins_from_binary(binary_str)

            client_socket.sendall(PREAMBLE)
            
            # Use custom function to wait for ACK with timeout
            if wait_for_ack(client_socket, TIMEOUT):
                print(f"Received ACK from PC2 for combination {binary_str}!")
            else:
                print(f"Did not receive expected ACK for combination {binary_str}. Stopping!")
                break


    except KeyboardInterrupt:
        print("Interrupted!")

    finally:
        client_socket.close()
        for board in arduinos:
            board.exit()

if __name__ == '__main__':
    main()
