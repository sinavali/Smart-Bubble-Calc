#!/usr/bin/env python3
"""
Smart-Bubble-Calc: Ultra-Fast Minimal Runner (Zero Downloads - Zero Bloat)
Invariant: ZERO half-space characters (\\u200c) allowed.
Culture: fa-IR, Tehran timezone, Iranian financial terminal & gold bazaar rules.
"""

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time
import urllib.request
import urllib.error
import webbrowser

# ANSI Color formatting
C_GOLD = "\033[38;2;212;175;55m"
C_EMERALD = "\033[38;2;0;230;118m"
C_AMBER = "\033[38;2;255;179;0m"
C_CORAL = "\033[38;2;255;82;82m"
C_CYAN = "\033[38;2;64;196;255m"
C_MUTED = "\033[38;2;144;153;168m"
C_BOLD = "\033[1m"
C_RESET = "\033[0m"

BACKEND_CONTAINER_NAME = "smart-bubble-dev-backend"
PODMAN_ANDROID_CONTAINER_NAME = "smart-bubble-android-emulator"
DEFAULT_BACKEND_PORT = 8080

backend_proc = None


def print_banner():
    banner = f"""{C_GOLD}{C_BOLD}
========================================================================
  SMART BUBBLE CALC // سامانه حباب سنج و نبض بازار
  Ultra-Fast Minimal Runner (Zero Downloads - Zero Bloat)
========================================================================{C_RESET}
"""
    print(banner)


def get_fedora_info() -> str:
    """Reads Fedora OS release details."""
    try:
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    return line.strip().split("=", 1)[1].strip('"')
    except Exception:
        pass
    return "Fedora Linux"


def locate_android_tools():
    """Locates adb and emulator binaries across PATH and standard SDK locations."""
    sdk_roots = [
        os.environ.get("ANDROID_HOME", ""),
        os.environ.get("ANDROID_SDK_ROOT", ""),
        os.path.expanduser("~/Android/Sdk"),
        os.path.expanduser("~/.android-sdk"),
        "/usr/lib/android-sdk",
        "/opt/android-sdk",
    ]

    adb_path = shutil.which("adb")
    emulator_path = shutil.which("emulator")

    for root in sdk_roots:
        if not root or not os.path.isdir(root):
            continue
        if not adb_path:
            candidate_adb = os.path.join(root, "platform-tools", "adb")
            if os.path.isfile(candidate_adb) and os.access(candidate_adb, os.X_OK):
                adb_path = candidate_adb
        if not emulator_path:
            candidate_emu = os.path.join(root, "emulator", "emulator")
            if os.path.isfile(candidate_emu) and os.access(candidate_emu, os.X_OK):
                emulator_path = candidate_emu

    return adb_path, emulator_path


def check_backend_health(port: int = DEFAULT_BACKEND_PORT) -> bool:
    """Verifies backend HTTP /healthz endpoint."""
    url = f"http://127.0.0.1:{port}/healthz"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "SmartBubble-DevRunner/1.0"})
        with urllib.request.urlopen(req, timeout=1.0) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return data.get("status") == "healthy"
    except Exception:
        return False
    return False


def get_shamsi_today(port: int = DEFAULT_BACKEND_PORT) -> str:
    """Fetches formatted Shamsi date from backend."""
    url = f"http://127.0.0.1:{port}/api/v1/shamsi/today"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "SmartBubble-DevRunner/1.0"})
        with urllib.request.urlopen(req, timeout=1.0) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return data.get("formatted", "")
    except Exception:
        pass
    return ""


def start_backend_service(port: int = DEFAULT_BACKEND_PORT, root_dir: str = ".") -> subprocess.Popen | None:
    """Starts the backend service natively or via Podman."""
    global backend_proc
    print(f"{C_CYAN}[BACKEND]{C_RESET} Starting Iranian financial calculation server on port {port}...")

    # Stop any previous leftover container
    subprocess.run(["podman", "rm", "-f", BACKEND_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    backend_dir = os.path.abspath(os.path.join(root_dir, "backend"))
    binary_path = os.path.join(backend_dir, "bubble-server")

    # If binary does not exist, compile it via cached podman golang image
    if not os.path.isfile(binary_path):
        print(f"{C_MUTED}[BUILD]{C_RESET} Compiling static Go backend binary...")
        build_cmd = [
            "podman", "run", "--rm",
            "-v", f"{os.path.abspath(root_dir)}:/app:Z",
            "-w", "/app/backend",
            "docker.io/library/golang:1.23-alpine",
            "sh", "-c", "CGO_ENABLED=0 go build -ldflags=\"-s -w\" -o bubble-server ./cmd/server"
        ]
        subprocess.run(build_cmd, check=True)

    # Fast-path: Native host execution (0s container overhead, zero downloads)
    try:
        proc = subprocess.Popen(
            [binary_path],
            cwd=backend_dir,
            env={**os.environ, "PORT": str(port), "CONFIG_PATH": "config.json"},
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        backend_proc = proc
    except Exception as e:
        print(f"{C_MUTED}[FALLBACK]{C_RESET} Native execution failed ({e}), using container...")
        run_cmd = [
            "podman", "run", "-d",
            "--name", BACKEND_CONTAINER_NAME,
            "-p", f"{port}:8080",
            "-v", f"{backend_dir}:/app:Z",
            "-w", "/app",
            "docker.io/library/alpine",
            "/app/bubble-server"
        ]
        subprocess.run(run_cmd, check=True)

    # Wait for /healthz to turn green
    print(f"{C_MUTED}[WAIT]{C_RESET} Initializing server on http://127.0.0.1:{port}...", end="", flush=True)
    for _ in range(20):
        time.sleep(0.2)
        print(".", end="", flush=True)
        if check_backend_health(port):
            print(f" {C_EMERALD}ONLINE{C_RESET}")
            shamsi = get_shamsi_today(port)
            if shamsi:
                print(f"{C_GOLD}[CALENDAR]{C_RESET} Tehran Shamsi Date: {shamsi}")
            return backend_proc

    print(f" {C_CORAL}TIMEOUT{C_RESET}")
    print(f"{C_CORAL}[ERROR]{C_RESET} Backend failed to respond within 4 seconds.")
    return backend_proc


def main():
    global backend_proc
    parser = argparse.ArgumentParser(description="Smart-Bubble-Calc ultra-fast minimal runner for Fedora")
    parser.add_argument("--port", type=int, default=DEFAULT_BACKEND_PORT, help="Backend port (default: 8080)")
    parser.add_argument("--backend-only", action="store_true", help="Start only backend API service")
    parser.add_argument("--no-browser", action="store_true", help="Do not automatically open web browser")
    parser.add_argument("--android", action="store_true", help="Connect to physical Android device or native AVD")
    parser.add_argument("--podman-android", action="store_true", help="Run containerized Android emulator via Podman with noVNC")
    parser.add_argument("--avd", type=str, default="", help="Specific AVD name to launch")
    parser.add_argument("--timeout", type=int, default=120, help="Emulator boot timeout in seconds")
    args = parser.parse_args()

    print_banner()

    fedora_ver = get_fedora_info()
    print(f"{C_BOLD}[HOST]{C_RESET} Operating System: {fedora_ver}")

    # Cleanup handler
    def cleanup_handler(signum, frame):
        print(f"\n{C_AMBER}[SHUTDOWN]{C_RESET} Stopping development services...")
        if backend_proc:
            try:
                backend_proc.terminate()
                backend_proc.wait(timeout=2)
            except Exception:
                try:
                    backend_proc.kill()
                except Exception:
                    pass
        subprocess.run(["podman", "stop", BACKEND_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if args.podman_android:
            subprocess.run(["podman", "stop", PODMAN_ANDROID_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"{C_EMERALD}[SHUTDOWN]{C_RESET} Clean exit. Khoda-hafez!")
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup_handler)
    signal.signal(signal.SIGTERM, cleanup_handler)

    # Step 1: Start Backend
    if check_backend_health(args.port):
        print(f"{C_EMERALD}[BACKEND]{C_RESET} Backend is already running on port {args.port}.")
        shamsi = get_shamsi_today(args.port)
        if shamsi:
            print(f"{C_GOLD}[CALENDAR]{C_RESET} Tehran Shamsi Date: {shamsi}")
    else:
        start_backend_service(port=args.port)

    # Step 2: If Podman Android explicitly requested
    if args.podman_android:
        print(f"\n{C_CYAN}[PODMAN-ANDROID]{C_RESET} Attempting containerized Android emulator...")
        print(f"{C_AMBER}[NOTE]{C_RESET} Note: Containerized Android requires ~5.8 GB download from docker.io.")
        cmd = [
            "podman", "run", "-d",
            "--name", PODMAN_ANDROID_CONTAINER_NAME,
            "-p", "6080:6080",
            "-p", "5555:5555",
            "--device", "/dev/kvm",
            "-e", "EMULATOR_DEVICE=Samsung Galaxy S10",
            "-e", "WEB_VNC=true",
            "docker.io/budtmo/docker-android:emulator_11.0"
        ]
        try:
            subprocess.run(cmd, check=True)
            print(f"{C_EMERALD}[PODMAN-ANDROID]{C_RESET} Container started at http://127.0.0.1:6080")
        except Exception as e:
            print(f"{C_CORAL}[PODMAN-ANDROID]{C_RESET} Failed to start container: {e}")

    # Step 3: If Android / Flutter explicitly requested
    if args.android:
        adb_bin, emulator_bin = locate_android_tools()
        if adb_bin:
            print(f"{C_EMERALD}[ADB]{C_RESET} Found adb at: {adb_bin}")
            subprocess.run([adb_bin, "reverse", f"tcp:{args.port}", f"tcp:{args.port}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        flutter_bin = shutil.which("flutter")
        if flutter_bin:
            print(f"{C_CYAN}[MOBILE]{C_RESET} Launching Flutter client...")
            subprocess.run([flutter_bin, "run"], cwd="mobile")

    # Step 4: Default Ultra-Fast Minimal Mode (Browser Mobile Simulator)
    simulator_url = f"http://127.0.0.1:{args.port}/"
    if not args.no_browser and not args.android and not args.backend_only:
        print(f"{C_CYAN}[WEB-SIMULATOR]{C_RESET} Opening mobile terminal viewer in your browser...")
        try:
            webbrowser.open(simulator_url)
        except Exception:
            pass

    print(f"\n{C_GOLD}{C_BOLD}[PRODUCT READY // آماده برای استفاده]{C_RESET}")
    print(f"  • {C_BOLD}Mobile Terminal UI:{C_RESET} {C_CYAN}{simulator_url}{C_RESET}")
    print(f"  • {C_BOLD}Backend Healthz:{C_RESET}    http://127.0.0.1:{args.port}/healthz")
    print(f"  • {C_BOLD}Market Quotes API:{C_RESET}  http://127.0.0.1:{args.port}/api/v1/market")
    print(f"  • {C_BOLD}Shamsi Today API:{C_RESET}   http://127.0.0.1:{args.port}/api/v1/shamsi/today")
    print(f"\n{C_MUTED}Interactive features available in browser view:")
    print("  1. 📈 Live Tehran Market Watch & Coin Bubbles (Emami, Bahar Azadi, Nim, Rob, Gerami)")
    print("  2. ⚖️ Legal Jewelry Calculator (18k, 24k, 21k, 740, 9% VAT strictly on Ojrat+Profit)")
    print("  3. 🧠 Smart DCA Multi-Step Investment Planner with Tehran Jalali Calendar")
    print(f"  4. ⚙️ Shamsi Date Picker & Converter{C_RESET}")
    print(f"\n{C_EMERALD}Press Ctrl+C to terminate services.{C_RESET}")

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
