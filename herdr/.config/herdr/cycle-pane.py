"""Cycle Herdr panes in the server's workspace, tab, and layout order."""

import argparse
import fcntl
import json
import os
import socket


def request(socket_path, method, params, expected_type):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(socket_path)
        message = {"id": "cycle-pane", "method": method, "params": params}
        connection.sendall((json.dumps(message) + "\n").encode())
        with connection.makefile("r") as response:
            value = json.loads(response.readline())
    if value.get("id") != message["id"]:
        raise RuntimeError("unexpected Herdr response id")
    if "error" in value:
        raise RuntimeError(value["error"]["message"])
    result = value["result"]
    if result.get("type") != expected_type:
        raise RuntimeError("unexpected Herdr result type")
    return result


def cycle(socket_path, direction):
    panes = request(socket_path, "pane.list", {}, "pane_list")["panes"]
    if len(panes) < 2:
        return
    current = next((index for index, pane in enumerate(panes) if pane["focused"]), None)
    if current is None:
        return
    step = 1 if direction == "next" else -1
    target = panes[(current + step) % len(panes)]["pane_id"]
    request(socket_path, "pane.focus", {"pane_id": target}, "pane_info")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("direction", choices=["next", "previous"])
    args = parser.parse_args()
    socket_path = os.environ["HERDR_SOCKET_PATH"]
    # Detached key commands can overlap. Keep one inode and lock read through focus.
    with open(socket_path + ".cycle.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        cycle(socket_path, args.direction)
