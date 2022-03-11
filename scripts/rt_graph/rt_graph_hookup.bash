#!/usr/bin/env bash

exit_handler()
{
	stty sane
}

trap exit_handler EXIT

export fifo_name="$(dirname "$(readlink -f "$0")")/rt_graph.fifo"
script -f -c "$*" >(cat - > "$fifo_name")
