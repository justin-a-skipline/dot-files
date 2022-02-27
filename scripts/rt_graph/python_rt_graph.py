#!/usr/bin/env python3
import argparse
import socket
import threading
import textwrap
import time
import queue
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import sys
from time import sleep

parser = argparse.ArgumentParser(description=textwrap.dedent("""
        Graphs incoming key-value pairs over socket 24242.
        Searches for string \\r\\rRTGRAPH at start of each line.
        This script can be used to interact or bytes can be sent
        UDP. The format for UDP packets is to prefix the string to the
        normal commands that would be used
        """),
        formatter_class=argparse.RawDescriptionHelpFormatter)

subparsers = parser.add_subparsers()

all_values = dict()

command_queue = queue.Queue(200)

def handle_add(args):
    if args.key not in all_values:
        all_values[args.key] = list()
    # automatically increment x value if none given
    x_value = len(all_values[args.key])
    if len(args.values) >= 2:
        x_value = args.values[1]
    y_value = args.values[0]
    all_values[args.key].append((x_value, y_value))
add_subparser = subparsers.add_parser('add', help='Add another value to graph')
add_subparser.set_defaults(func=handle_add)
add_subparser.add_argument('key', type=str, help='name of item')
add_subparser.add_argument('values', nargs='+', type=float, help='y and optional x values')

def handle_clear_graph(args):
    all_values.clear()
clear_graph_subparser = subparsers.add_parser('clear_graph', help='Clear the graph')
clear_graph_subparser.set_defaults(func=handle_clear_graph)

def server_thread():
    command_prefix = '\r\rRTGRAPH '
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.bind(('localhost', 24242))

        message = ""
        while True:
            message += sock.recv(1024).decode('utf-8')
            print(message)
            if len(message) > 2048:
                message = message[-2048:]
            start_of_command = message.find(command_prefix)
            # is the start of a message in there?
            if start_of_command == -1:
                message = message[-len(command_prefix):] # throw away guaranteed worthless chars
                continue
            print(start_of_command)
            try: # try to find end of command
                index = message.index('\n')
            except:
                continue

            message_to_check = message[start_of_command + len(command_prefix):index] # save message to parse
            message = message[index + 1:] # throw away chars about to be used
            try:
                args = parser.parse_args(message_to_check.split())
            except:
                continue

            command_queue.put(args)

fig = plt.figure()
ax = plt.subplot()
def plotData(unused):
    ax.cla()
    for name, data in all_values.items():
        x_list, y_list = zip(*data)
        ax.plot(x_list, y_list, label=name) # how to do this?
        ax.legend()

def graph_thread():
    ani = FuncAnimation(fig, plotData, interval=100)
    plt.show()

def command_thread():
   while True:
       args = None
       try: args = command_queue.get(timeout=0.5)
       except KeyboardInterrupt: sys.exit(1)
       except: continue
       if args is not None and hasattr(args, 'func'):
           args.func(args)

if __name__ == "__main__":
    args = parser.parse_args()

    if hasattr(args, 'func'):
        args.func(args)
    else:
       threading.Thread(target=server_thread, daemon=True).start()
       threading.Thread(target=command_thread, daemon=True).start()
       graph_thread()

