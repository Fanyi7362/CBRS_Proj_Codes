#!/usr/bin/env python

import argparse
import numpy as np
import uhd

def parse_args():
    """Parse the command line arguments"""
    parser = argparse.ArgumentParser()
    # set receive buffer 256 (default 32)
    parser.add_argument("-a", "--args", default="num_recv_frames=256", type=str)
    parser.add_argument("-o", "--output-file", default="rx_samples.bin", type=str)
    parser.add_argument("-f", "--freq", default=3600e6, type=float)
    parser.add_argument("-r", "--rate", default=1e6, type=float)
    parser.add_argument("-d", "--duration", default=10.0, type=float)
    parser.add_argument("-c", "--channels", default=0, nargs="+", type=int)
    parser.add_argument("-g", "--gain", type=int, default=10)
    parser.add_argument("-n", "--numpy", default=False, action="store_true",
                        help="Save output file in NumPy format (default: No)")
    return parser.parse_args()

def main():
    """RX samples and write to file"""
    args = parse_args()
    usrp = uhd.usrp.MultiUSRP(args.args)

    num_samps = int(np.ceil(args.duration*args.rate)) # number of samples received
    center_freq = args.freq # Hz
    sample_rate = args.rate # Hz
    gain = args.gain # dB

    usrp.set_rx_rate(sample_rate, 0)
    usrp.set_rx_freq(uhd.libpyuhd.types.tune_request(center_freq), 0)
    usrp.set_rx_gain(gain, 0)

    # Set up the stream and receive buffer
    st_args = uhd.usrp.StreamArgs("fc32", "sc16")
    if not isinstance(args.channels, list):
        args.channels = [args.channels]
    st_args.channels = args.channels
    metadata = uhd.types.RXMetadata()
    streamer = usrp.get_rx_stream(st_args)
    # print(streamer.get_max_num_samps())  # get max buffer size
    # max buffer size of B210 = 2040
    recv_buffer = np.zeros((1, 1000), dtype=np.complex64)

    # Start Stream
    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.start_cont)
    stream_cmd.stream_now = True
    streamer.issue_stream_cmd(stream_cmd)

    # Receive Samples
    samples = np.zeros(num_samps, dtype=np.complex64)
    for i in range(num_samps//1000):
        streamer.recv(recv_buffer, metadata)
        samples[i*1000:(i+1)*1000] = recv_buffer[0]

    # Stop Stream
    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.stop_cont)
    streamer.issue_stream_cmd(stream_cmd)

    # print(samples[0:100])
    # Save File
    with open(args.output_file, 'wb') as out_file:
        if args.numpy:
            np.save(out_file, samples, allow_pickle=False, fix_imports=False)
        else:
            samples.tofile(out_file)
    
    print('Samples saved to {}!'.format(args.output_file))

if __name__ == "__main__":
    main()