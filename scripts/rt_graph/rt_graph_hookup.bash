#!/usr/bin/env bash

exit_handler()
{
	stty sane
}

trap exit_handler EXIT

script -f -c "$*" >(cat - >/dev/udp/localhost/24242)
