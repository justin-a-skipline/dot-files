#!/usr/bin/env python3
"""Own a pty for claude and relay every byte untouched.

Nothing here parses escape sequences, so claude's truecolor output reaches the
terminal exactly as written. That is the whole reason this exists instead of
screen, which predates 24-bit color and rewrites it into something else.

Text written to the FIFO named by $CLAUDE_PTY_FIFO is delivered to claude's input
as real keystrokes -- the capability `screen -X stuff` used to provide.
"""

import fcntl
import os
import pty
import select
import signal
import sys
import termios
import tty

BUF = 65536


def copy_winsize(dest_fd):
    try:
        packed = fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(dest_fd, termios.TIOCSWINSZ, packed)
    except OSError:
        pass


def read_available(fd):
    try:
        return os.read(fd, BUF)
    except OSError:
        return b""


def write_all(fd, data):
    while data:
        try:
            data = data[os.write(fd, data):]
        except BlockingIOError:
            select.select([], [fd], [])
        except OSError:
            return


def spawn(argv, fifo_path):
    pid, master = pty.fork()
    if pid == 0:
        os.environ["CLAUDE_PTY_FIFO"] = fifo_path
        try:
            os.execvp(argv[0], argv)
        except OSError as exc:
            sys.stderr.write("claude-pty: cannot run %s: %s\n" % (argv[0], exc))
            os._exit(127)
    return pid, master


def relay(master, fifo, wake_r):
    stdin_fd = sys.stdin.fileno()
    stdout_fd = sys.stdout.fileno()
    watching = [stdin_fd, master, fifo, wake_r]

    while True:
        try:
            readable, _, _ = select.select(watching, [], [])
        except InterruptedError:
            continue

        if wake_r in readable:
            read_available(wake_r)
            copy_winsize(master)

        if fifo in readable:
            write_all(master, read_available(fifo))

        if stdin_fd in readable:
            data = read_available(stdin_fd)
            if data:
                write_all(master, data)
            else:
                watching.remove(stdin_fd)

        if master in readable:
            data = read_available(master)
            if not data:
                return
            write_all(stdout_fd, data)


def main():
    argv = sys.argv[1:] or ["claude"]

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or os.path.expanduser("~/.claude")
    fifo_path = os.path.join(runtime_dir, "claude-pty-%d.fifo" % os.getpid())
    os.makedirs(runtime_dir, exist_ok=True)
    if os.path.exists(fifo_path):
        os.unlink(fifo_path)
    os.mkfifo(fifo_path, 0o600)

    pid, master = spawn(argv, fifo_path)
    copy_winsize(master)

    # O_RDWR holds a writer open ourselves, so the FIFO never reports EOF and the
    # select loop never has to reopen it between injections.
    fifo = os.open(fifo_path, os.O_RDWR | os.O_NONBLOCK)

    wake_r, wake_w = os.pipe()
    os.set_blocking(wake_w, False)
    signal.set_wakeup_fd(wake_w)
    signal.signal(signal.SIGWINCH, lambda *_: None)

    saved = termios.tcgetattr(sys.stdin.fileno())
    tty.setraw(sys.stdin.fileno())
    try:
        relay(master, fifo, wake_r)
    finally:
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSAFLUSH, saved)
        signal.set_wakeup_fd(-1)
        os.close(fifo)
        try:
            os.unlink(fifo_path)
        except OSError:
            pass

    return os.waitstatus_to_exitcode(os.waitpid(pid, 0)[1])


if __name__ == "__main__":
    sys.exit(main())
