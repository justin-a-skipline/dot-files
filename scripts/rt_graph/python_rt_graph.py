#!/usr/bin/env python3
import argparse
import datetime
import os
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

global_data_lock = threading.Lock()
all_values = dict()
paused = False
titleString = ""

command_queue = queue.Queue(200)

def handle_set_title(args):
    global titleString
    titleString = args.title
add_subparser = subparsers.add_parser('set_title', help='Sets title of graph')
add_subparser.set_defaults(func=handle_set_title)
add_subparser.add_argument('title', type=str, help='title text')

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

def handle_add_time(args):
    if args.key not in all_values:
        all_values[args.key] = list()
    # automatically increment x value if none given
    x_value = datetime.datetime.now()
    y_value = args.value
    all_values[args.key].append((x_value, y_value))
add_time_subparser = subparsers.add_parser('add_time', help='Add another value to graph with auto timestamp')
add_time_subparser.set_defaults(func=handle_add_time)
add_time_subparser.add_argument('key', type=str, help='name of item')
add_time_subparser.add_argument('value', type=float, help='y value')

def handle_clear_graph(args):
    all_values.clear()
clear_graph_subparser = subparsers.add_parser('clear_graph', help='Clear the graph')
clear_graph_subparser.set_defaults(func=handle_clear_graph)

def handle_pause_graph(args):
    global paused
    paused = args.paused != 0
pause_graph_subparser = subparsers.add_parser('pause_graph', help='Pause updates so graph can be fiddled with')
pause_graph_subparser.set_defaults(func=handle_pause_graph)
pause_graph_subparser.add_argument('paused', type=int, help='1 paused, 0 unpaused')

def server_thread():
    fifo_name = os.path.dirname(os.path.realpath(__file__))+"/rt_graph.fifo"
    try:
        os.mkfifo(fifo_name)
    except FileExistsError:
        print("{0} exists, using".format(fifo_name))

    command_prefix = '\r\rRTGRAPH '
    while True:
        with open(fifo_name, "rb") as fifo:
            message = ""
            while True:
                line = fifo.readline(1024)
                if len(line) == 0:
                    break
                print(line)
                message += line.decode('utf-8')
                if len(message) > 2048:
                    message = message[-2048:]
                start_of_command = message.find(command_prefix)
                # is the start of a message in there?
                if start_of_command == -1:
                    message = message[-len(command_prefix):] # throw away guaranteed worthless chars
                    continue
                try: # try to find end of command
                    index = message.index('\n', start_of_command)
                except:
                    continue

                message_to_check = message[start_of_command + len(command_prefix):index].rstrip() # save message to parse
                message = message[index + 1:] # throw away chars about to be used
                print(message_to_check)
                try:
                    args = parser.parse_args(message_to_check.split())
                except:
                    continue

                command_queue.put(args)

fig = plt.figure()
ax = plt.subplot()
def plotData(unused):
    with global_data_lock:
        global paused
        if paused == True:
            return
        ax.cla()
        global titleString
        ax.set_title(titleString)
        for name, data in all_values.items():
            x_list, y_list = zip(*data)
            ax.plot(x_list, y_list, label=name, marker='*')
            ax.legend()
            ax.grid(True)
            plt.gcf().autofmt_xdate()

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
            with global_data_lock:
                args.func(args)

if __name__ == "__main__":
    args = parser.parse_args()

    if hasattr(args, 'func'):
        args.func(args)
    else:
       threading.Thread(target=server_thread, daemon=True).start()
       threading.Thread(target=command_thread, daemon=True).start()
       graph_thread()

