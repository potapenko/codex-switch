#!/usr/bin/env python3
"""Run a release command with a hard timeout."""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("timeout_seconds", type=float)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("missing command")

    process = subprocess.Popen(command, start_new_session=True)
    try:
        return process.wait(timeout=args.timeout_seconds)
    except subprocess.TimeoutExpired:
        print(f"timed out after {args.timeout_seconds:.0f}s: {' '.join(command)}", file=sys.stderr)
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        return 124


if __name__ == "__main__":
    raise SystemExit(main())
