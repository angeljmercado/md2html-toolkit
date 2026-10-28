#!/usr/bin/env python3
"""Drag-and-drop front end for build.sh (standard library only).

Runs a small web page on 127.0.0.1. Drop .md files on it, it runs build.sh
on each one and gives you the HTML to download. Nothing leaves this machine.
Usage: python3 gui.py [--port N] [--no-browser]
"""
import argparse
import os
import re
import secrets
import shutil
import subprocess
import sys
import tempfile
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

TOOLKIT = Path(__file__).resolve().parent
MAX_BYTES = 20 * 1024 * 1024
BUILD_TIMEOUT = 120
TOKEN = secrets.token_urlsafe(24)


def find_bash():
    """Find bash for build.sh. On Windows use Git Bash, not the WSL stub."""
    if os.name == "nt":
        roots = [os.environ.get("ProgramFiles"), os.environ.get("ProgramFiles(x86)"),
                 os.environ.get("LOCALAPPDATA")]
        for root in filter(None, roots):
            for rel in ("Git/bin/bash.exe", "Programs/Git/bin/bash.exe"):
                cand = Path(root) / rel
                if cand.is_file():
                    return str(cand)
    return shutil.which("bash")


def build(name, data):
    """Return (ok, html_bytes_or_error_text)."""
    bash = find_bash()
    if not bash:
        return False, "bash not found (on Windows, install Git for Windows)."
    stem = re.sub(r"[^\w.\- ]", "_", Path(name).stem) or "document"
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / f"{stem}.md"
        out = Path(tmp) / f"{stem}.html"
        src.write_bytes(data)
        try:
            r = subprocess.run(
                [bash, (TOOLKIT / "build.sh").as_posix(), src.as_posix(), out.as_posix()],
                cwd=tmp, capture_output=True, text=True, timeout=BUILD_TIMEOUT)
        except subprocess.TimeoutExpired:
            return False, f"Build timed out after {BUILD_TIMEOUT}s."
        if r.returncode != 0 or not out.is_file():
            return False, (r.stderr or r.stdout or "Build failed.").strip()[-2000:]
        return True, out.read_bytes()


class Handler(BaseHTTPRequestHandler):
    server_version = "md2html-gui"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s\n" % (fmt % args))

    def _reply(self, code, body, ctype="text/plain; charset=utf-8", extra=None):
        if isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def _host_ok(self):
        # Block DNS rebinding: only accept requests addressed to our own localhost port.
        port = self.server.server_address[1]
        return self.headers.get("Host", "") in (f"127.0.0.1:{port}", f"localhost:{port}")

    def do_GET(self):
        if not self._host_ok():
            return self._reply(403, "Forbidden")
        if urlparse(self.path).path != "/":
            return self._reply(404, "Not found")
        page = (TOOLKIT / "gui.html").read_text(encoding="utf-8").replace("__TOKEN__", TOKEN)
        self._reply(200, page, "text/html; charset=utf-8")

    def do_POST(self):
        url = urlparse(self.path)
        if not self._host_ok() or self.headers.get("X-Token") != TOKEN:
            return self._reply(403, "Forbidden")
        if url.path != "/build":
            return self._reply(404, "Not found")
        name = parse_qs(url.query).get("name", ["document.md"])[0]
        if not name.lower().endswith((".md", ".markdown")):
            return self._reply(400, "Only .md or .markdown files are accepted.")
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > MAX_BYTES:
            return self._reply(400, f"File must be 1 byte to {MAX_BYTES // 1048576} MB.")
        ok, result = build(name, self.rfile.read(length))
        if ok:
            self._reply(200, result, "text/html; charset=utf-8")
        else:
            self._reply(500, result)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--port", type=int, default=8765, help="default 8765; 0 = any free port")
    ap.add_argument("--no-browser", action="store_true")
    args = ap.parse_args()
    try:
        httpd = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    except OSError:
        httpd = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    url = f"http://127.0.0.1:{httpd.server_address[1]}/"
    print(f"md2html GUI running at {url}  (Ctrl+C to stop)")
    if not args.no_browser:
        threading.Timer(0.5, webbrowser.open, args=(url,)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
