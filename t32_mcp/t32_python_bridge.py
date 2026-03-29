#!/usr/bin/env python3
"""TRACE32 Python RCL bridge — mimics t32rem CLI using lauterbach-trace32-rcl.

Usage: t32_python_bridge.py <host> port=<port> [INTERCOM=<name>] <command...>

This script acts as a drop-in replacement for the t32rem binary, using the
lauterbach-trace32-rcl Python library instead of the native Lauterbach tool.

Install: pip install lauterbach-trace32-rcl

Environment variables:
  T32_RCL_PACKLEN  — RCL packet length (default: 1024)
  T32_RCL_TIMEOUT  — Connection timeout in seconds (default: 10)
"""

import sys
import os
import tempfile


def parse_args(args):
    """Parse t32rem-style arguments: <host> port=<port> [INTERCOM=<name>] <command...>"""
    if len(args) < 2:
        return None, None, None, None

    host = args[0]
    port = 20000
    intercom = ""
    cmd_start = 1

    i = 1
    while i < len(args):
        arg = args[i]
        if arg.startswith("port="):
            port = int(arg[5:])
        elif arg.startswith("INTERCOM="):
            intercom = arg[9:]
        else:
            cmd_start = i
            break
        i += 1
        cmd_start = i

    command = " ".join(args[cmd_start:])
    return host, port, intercom, command


def run_command(t32, command):
    """Execute a TRACE32 command and return the text output."""
    upper = command.strip().upper()

    # PING
    if upper == "PING":
        t32.ping()
        return "OK"

    # EVAL <expression>
    if upper.startswith("EVAL "):
        expr = command.strip()[5:]
        try:
            result = t32.eval_string(expr)
            return str(result)
        except Exception:
            # Some EVAL expressions return integers
            try:
                result = t32.eval_int(expr)
                return str(result)
            except Exception as e:
                return f"eval error: {e}"

    # PRACTICE.STATE() query (used for polling)
    if upper == "EVAL PRACTICE.STATE()":
        try:
            state = t32.get_practice_state()
            return str(state)
        except Exception:
            return "0"

    # WinPrint commands — redirect to temp file and read
    if upper.startswith("WINPRINT."):
        tmp = tempfile.mktemp(suffix=".txt", prefix="t32_bridge_")
        try:
            t32.cmd(f"PRinTer.FILE {tmp}")
            t32.cmd(command)
            t32.cmd("PRinTer.FILE")  # close redirect
            try:
                with open(tmp) as f:
                    return f.read()
            except FileNotFoundError:
                return ""
        finally:
            try:
                os.unlink(tmp)
            except OSError:
                pass

    # DIALOG action commands (explicit recognition for better error handling)
    if upper.startswith("DIALOG.SET ") or upper.startswith("DIALOG.DESELECT ") or upper.startswith("DIALOG.DISABLE ") or \
       upper.startswith("DIALOG.ENABLE ") or upper.startswith("DIALOG.EXECUTE ") or \
       upper == "DIALOG.END":
        t32.cmd(command)
        return "OK"

    # DO command (explicit recognition)
    if upper.startswith("DO "):
        t32.cmd(command)
        return ""

    # CD / CHDIR command
    if upper.startswith("CD ") or upper.startswith("CD.DO ") or upper.startswith("CHDIR "):
        t32.cmd(command)
        return ""

    # MENU commands
    if upper.startswith("MENU."):
        t32.cmd(command)
        return ""

    # All other PRACTICE commands
    t32.cmd(command)
    return ""


def main():
    args = sys.argv[1:]
    host, port, intercom, command = parse_args(args)

    if host is None or not command:
        print(
            "Usage: t32_python_bridge.py <host> port=<port> [INTERCOM=<name>] <command...>",
            file=sys.stderr,
        )
        sys.exit(1)

    packlen = int(os.environ.get("T32_RCL_PACKLEN", "1024"))
    timeout = int(os.environ.get("T32_RCL_TIMEOUT", "10"))

    try:
        import lauterbach.trace32.rcl as t32
    except ImportError:
        print(
            "python-rcl error: lauterbach-trace32-rcl not installed. "
            "Run: pip install lauterbach-trace32-rcl",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        t32.init()
        t32.config(node=host, port=port, packlen=packlen, timeout=timeout)
        if intercom:
            # INTERCOM name selects a specific TRACE32 instance
            t32.config(intercom=intercom)
        t32.attach(dev=1)
    except Exception as e:
        print(f"python-rcl connection error: {e}", file=sys.stderr)
        sys.exit(2)

    try:
        result = run_command(t32, command)
        if result:
            print(result)
    except Exception as e:
        print(f"python-rcl error: {e}", file=sys.stderr)
        sys.exit(3)
    finally:
        try:
            t32.exit()
        except Exception:
            pass

    sys.exit(0)


if __name__ == "__main__":
    main()
