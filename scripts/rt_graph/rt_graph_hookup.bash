#!/usr/bin/env bash

script -f -c "$*" >(cat - >/dev/udp/localhost/24242)
