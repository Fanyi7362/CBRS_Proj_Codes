#!/usr/bin/env python
#
# Copyright 2017-2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
"""
RX samples to file using Python API
"""

import argparse
import numpy as np
import uhd


def parse_args():
    """Parse the command line arguments"""
    parser = argparse.ArgumentParser()
    # set receive buffer 256 (default 32)
    # "num_recv_frames=256"
    # "serial=31993A8"
    # "serial=3199405"
    parser.add_argument("-a", "--args", default="serial=31993A8", type=str)
    parser.add_argument("-o", "--output-file", default="rx_samples.bin", type=str)
    parser.add_argument("-f", "--freq", default=3600e6, type=float)
    parser.add_argument("-r", "--rate", default=1e6, type=float)
    parser.add_argument("-d", "--duration", default=10.0, type=float)
    parser.add_argument("-c", "--channels", default=0, nargs="+", type=int)
    parser.add_argument("-g", "--gain", type=int, default=50)
    parser.add_argument("-n", "--numpy", default=False, action="store_true",
                        help="Save output file in NumPy format (default: No)")
    return parser.parse_args()


def main():
    """RX samples and write to file"""
    args = parse_args()
    usrp = uhd.usrp.MultiUSRP(args.args)
    num_samps = int(np.ceil(args.duration*args.rate))
    if not isinstance(args.channels, list):
        args.channels = [args.channels]
    samps = usrp.recv_num_samps(num_samps, args.freq, args.rate, args.channels, args.gain)
    with open(args.output_file, 'wb') as out_file:
        if args.numpy:
            np.save(out_file, samps, allow_pickle=False, fix_imports=False)
        else:
            samps.tofile(out_file)
            
    print('Samples saved to: {}!'.format(args.output_file))

if __name__ == "__main__":
    main()
