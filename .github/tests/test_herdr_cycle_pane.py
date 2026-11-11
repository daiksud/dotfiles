import fcntl
import json
import os
from pathlib import Path
import socketserver
import subprocess
import sys
import tempfile
import threading
import unittest


SCRIPT = Path(__file__).resolve().parents[2] / "herdr/.config/herdr/cycle-pane.py"


class HerdrHandler(socketserver.StreamRequestHandler):
    def handle(self):
        request = json.loads(self.rfile.readline())
        self.server.requests.append(request)
        self.server.request_received.set()
        if request["method"] in self.server.responses:
            response = self.server.responses[request["method"]](request)
            if isinstance(response, bytes):
                self.wfile.write(response)
            else:
                self.wfile.write((json.dumps(response) + "\n").encode())
            return
        if request["method"] == "pane.list":
            result = {"type": "pane_list", "panes": self.server.panes}
        elif request["method"] == "pane.focus":
            target = request["params"]["pane_id"]
            for pane in self.server.panes:
                pane["focused"] = pane["pane_id"] == target
            result = {"type": "pane_info", "pane": {"pane_id": target}}
        else:
            raise AssertionError(request)
        self.wfile.write((json.dumps({"id": request["id"], "result": result}) + "\n").encode())


class CyclePaneTests(unittest.TestCase):
    def setUp(self):
        # Keep UNIX socket names below macOS's path-length limit.
        self.temp = tempfile.TemporaryDirectory(dir="/tmp")
        self.addCleanup(self.temp.cleanup)
        self.socket_path = str(Path(self.temp.name) / "herdr.sock")
        self.server = socketserver.UnixStreamServer(self.socket_path, HerdrHandler)
        self.server.panes = [
            {"pane_id": "w9:p7", "workspace_id": "w9", "tab_id": "w9:t2", "focused": False},
            {"pane_id": "w9:p3", "workspace_id": "w9", "tab_id": "w9:t2", "focused": True},
            {"pane_id": "w2:p8", "workspace_id": "w2", "tab_id": "w2:t4", "focused": False},
        ]
        self.server.requests = []
        self.server.responses = {}
        self.server.request_received = threading.Event()
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(thread.join)
        self.addCleanup(self.server.shutdown)

    def start_cycle(self, direction="next"):
        return subprocess.Popen(
            [sys.executable, str(SCRIPT), direction],
            env={**os.environ, "HERDR_SOCKET_PATH": self.socket_path, "HERDR_ACTIVE_PANE_ID": "w9:p7"},
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )

    def run_cycle(self, direction="next"):
        with self.start_cycle(direction) as process:
            try:
                stdout, stderr = process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate()
                raise
            return subprocess.CompletedProcess(process.args, process.returncode, stdout, stderr)

    def test_next_crosses_workspace_in_server_order(self):
        result = self.run_cycle()
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("w2:p8", next(p["pane_id"] for p in self.server.panes if p["focused"]))
        self.assertEqual(["pane.list", "pane.focus"], [r["method"] for r in self.server.requests])
        self.assertEqual({}, self.server.requests[0]["params"])

    def test_previous_crosses_workspace_in_server_order(self):
        for pane in self.server.panes:
            pane["focused"] = pane["pane_id"] == "w2:p8"
        result = self.run_cycle("previous")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("w9:p3", next(p["pane_id"] for p in self.server.panes if p["focused"]))

    def test_wraps_at_both_ends(self):
        for direction, current, expected in (
            ("next", "w2:p8", "w9:p7"),
            ("previous", "w9:p7", "w2:p8"),
        ):
            with self.subTest(direction=direction):
                for pane in self.server.panes:
                    pane["focused"] = pane["pane_id"] == current
                result = self.run_cycle(direction)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(expected, next(p["pane_id"] for p in self.server.panes if p["focused"]))

    def test_no_move_without_another_pane_or_current_focus(self):
        for state in ("empty", "single", "unfocused"):
            with self.subTest(state=state):
                if state == "empty":
                    self.server.panes = []
                elif state == "single":
                    self.server.panes = [{"pane_id": "w4:p6", "focused": True}]
                else:
                    self.server.panes = [
                        {"pane_id": "w4:p6", "focused": False},
                        {"pane_id": "w5:p1", "focused": False},
                    ]
                self.server.requests.clear()
                result = self.run_cycle()
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(["pane.list"], [r["method"] for r in self.server.requests])

    def test_invalid_list_response_never_focuses(self):
        responses = {
            "api_error": lambda r: {"id": r["id"], "error": {"code": "unavailable", "message": "unavailable"}},
            "wrong_id": lambda r: {"id": "unrelated", "result": {"type": "pane_list", "panes": self.server.panes}},
            "wrong_type": lambda r: {"id": r["id"], "result": {"type": "workspace_list", "panes": self.server.panes}},
            "invalid_json": lambda r: b"not json\n",
        }
        for name, response in responses.items():
            with self.subTest(response=name):
                self.server.responses = {"pane.list": response}
                self.server.requests.clear()
                result = self.run_cycle()
                self.assertNotEqual(0, result.returncode)
                self.assertTrue(result.stderr)
                self.assertEqual(["pane.list"], [r["method"] for r in self.server.requests])

    def test_failed_focus_is_not_retried(self):
        self.server.responses["pane.focus"] = lambda r: {
            "id": r["id"], "error": {"code": "pane_not_found", "message": "pane closed"},
        }
        result = self.run_cycle()
        self.assertNotEqual(0, result.returncode)
        self.assertIn("pane closed", result.stderr)
        self.assertEqual(["pane.list", "pane.focus"], [r["method"] for r in self.server.requests])

    def test_serializes_read_and_focus_for_repeated_presses(self):
        processes = []
        try:
            with open(self.socket_path + ".cycle.lock", "a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                processes.append(self.start_cycle())
                self.assertFalse(self.server.request_received.wait(0.3), "read started before acquiring lock")
                fcntl.flock(lock, fcntl.LOCK_UN)
            _, stderr = processes[0].communicate(timeout=5)
            self.assertEqual(0, processes[0].returncode, stderr)

            for _ in range(11):
                processes.append(self.start_cycle())
            for process in processes[1:]:
                _, stderr = process.communicate(timeout=5)
                self.assertEqual(0, process.returncode, stderr)
            self.assertEqual(
                ["w2:p8", "w9:p7", "w9:p3"] * 4,
                [r["params"]["pane_id"] for r in self.server.requests if r["method"] == "pane.focus"],
            )
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                process.communicate(timeout=5)


if __name__ == "__main__":
    unittest.main()
