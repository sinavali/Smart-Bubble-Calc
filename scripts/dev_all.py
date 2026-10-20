#!/usr/bin/env python3
"""
Smart-Bubble-Calc: Local Development & Android Testing Runner (Fedora Linux)
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
DEFAULT_BACKEND_PORT = 8080


def print_banner():
    banner = f"""{C_GOLD}{C_BOLD}
========================================================================
  SMART BUBBLE CALC // سامانه حباب سنج و نبض بازار
  Local Development & Android Product Runner (Fedora Linux)
========================================================================{C_RESET}
"""
    print(banner)


def check_kvm() -> bool:
    """Checks whether hardware virtualization (/dev/kvm) is available on Fedora."""
    kvm_path = "/dev/kvm"
    if os.path.exists(kvm_path):
        is_writable = os.access(kvm_path, os.R_OK | os.W_OK)
        if is_writable:
            print(f"{C_EMERALD}[KVM]{C_RESET} Hardware virtualization (/dev/kvm) is available and writable.")
            return True
        else:
            print(f"{C_AMBER}[KVM]{C_RESET} /dev/kvm exists but requires group permission. Run: sudo usermod -aG kvm $USER")
            return False
    else:
        print(f"{C_CORAL}[KVM]{C_RESET} /dev/kvm not found! Hardware virtualization may be disabled in BIOS.")
        return False


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
    """Locates adb and emulator binaries across PATH and standard Android SDK locations."""
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


def list_configured_avds(emulator_bin: str) -> list[str]:
    """Lists available Android Virtual Devices (AVDs)."""
    if not emulator_bin:
        return []
    try:
        res = subprocess.run([emulator_bin, "-list-avds"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        lines = [line.strip() for line in res.stdout.splitlines() if line.strip()]
        return lines
    except Exception:
        return []


def get_running_devices(adb_bin: str) -> list[str]:
    """Returns list of online running adb devices."""
    if not adb_bin:
        return []
    try:
        res = subprocess.run([adb_bin, "devices"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        devices = []
        for line in res.stdout.splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == "device":
                devices.append(parts[0])
        return devices
    except Exception:
        return []


def check_backend_health(port: int = DEFAULT_BACKEND_PORT) -> bool:
    """Verifies backend HTTP /healthz endpoint."""
    url = f"http://127.0.0.1:{port}/healthz"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "SmartBubble-DevRunner/1.0"})
        with urllib.request.urlopen(req, timeout=1.5) as resp:
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
        with urllib.request.urlopen(req, timeout=1.5) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                return data.get("formatted", "")
    except Exception:
        pass
    return ""


def start_backend_service(port: int = DEFAULT_BACKEND_PORT, root_dir: str = ".") -> subprocess.Popen | None:
    """Starts the backend service using Podman container or native Go."""
    print(f"{C_CYAN}[BACKEND]{C_RESET} Starting Iranian financial calculation server on port {port}...")

    # Stop any previous leftover container
    subprocess.run(["podman", "rm", "-f", BACKEND_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Prefer precompiled binary if exists, else compile inside container
    binary_path = os.path.join(root_dir, "backend", "bubble-server")
    if not os.path.isfile(binary_path):
        print(f"{C_MUTED}[BUILD]{C_RESET} Compiling static Go backend binary...")
        build_cmd = [
            "podman", "run", "--rm",
            "-v", f"{os.path.abspath(root_dir)}:/app:Z",
            "-w", "/app/backend",
            "docker.io/library/golang:1.23-alpine",
            "sh", "-c", "CGO_ENABLED=0 go build -ldflags=\"-s -w\" -o bubble-server ./cmd/server"
        ]
        subprocess.run(build_cmd, check=True, stdout=subprocess.DEVNULL)

    # Run the compiled backend container
    run_cmd = [
        "podman", "run", "-d",
        "--name", BACKEND_CONTAINER_NAME,
        "-p", f"{port}:8080",
        "-v", f"{os.path.abspath(os.path.join(root_dir, 'backend'))}:/app:Z",
        "-w", "/app",
        "docker.io/library/alpine",
        "/app/bubble-server"
    ]
    subprocess.run(run_cmd, check=True)

    # Wait for /healthz to turn green
    print(f"{C_MUTED}[WAIT]{C_RESET} Waiting for backend cache initialization on http://127.0.0.1:{port}...", end="", flush=True)
    for _ in range(30):
        time.sleep(0.5)
        print(".", end="", flush=True)
        if check_backend_health(port):
            print(f" {C_EMERALD}ONLINE{C_RESET}")
            shamsi = get_shamsi_today(port)
            if shamsi:
                print(f"{C_GOLD}[CALENDAR]{C_RESET} Tehran Shamsi Date: {shamsi}")
            return None

    print(f" {C_CORAL}TIMEOUT{C_RESET}")
    print(f"{C_CORAL}[ERROR]{C_RESET} Backend failed to respond within 15 seconds.")
    return None


def print_fedora_android_setup_guide():
    """Prints clear, copy-pasteable instructions for Fedora Linux developers."""
    guide = f"""
{C_AMBER}{C_BOLD}[FEDORA ANDROID SETUP REQUIRED]{C_RESET}
To run the full Android emulator on Fedora Linux, execute the following commands:

1. Install Android CLI tools & JDK:
   {C_GOLD}sudo dnf install -y android-tools java-17-openjdk-devel{C_RESET}

2. (Recommended) Install Android Studio for Fedora via Flatpak or Official RPM:
   {C_GOLD}flatpak install -y flathub com.google.AndroidStudio{C_RESET}
   or download Android Command Line Tools to ~/Android/Sdk.

3. Verify KVM permissions for hardware acceleration:
   {C_GOLD}sudo usermod -aG kvm $USER{C_RESET}

4. Create a virtual device (AVD) in Android Studio Device Manager:
   Recommended: Pixel 7 / Pixel 8, System Image: Android 14 (API 34) or 15 (API 35) with Google APIs x86_64.
"""
    print(guide)


def main():
    parser = argparse.ArgumentParser(description="Smart-Bubble-Calc local development runner for Fedora")
    parser.add_argument("--port", type=int, default=DEFAULT_BACKEND_PORT, help="Backend port (default: 8080)")
    parser.add_argument("--backend-only", action="store_true", help="Start only backend service")
    parser.add_argument("--emulator-only", action="store_true", help="Start only Android emulator")
    parser.add_argument("--avd", type=str, default="", help="Specific AVD name to launch")
    parser.add_argument("--timeout", type=int, default=120, help="Emulator boot timeout in seconds")
    args = parser.parse_args()

    print_banner()

    fedora_ver = get_fedora_info()
    print(f"{C_BOLD}[HOST]{C_RESET} Operating System: {fedora_ver}")
    kvm_ok = check_kvm()

    adb_bin, emulator_bin = locate_android_tools()
    if adb_bin:
        print(f"{C_EMERALD}[ADB]{C_RESET} Found adb at: {adb_bin}")
    else:
        print(f"{C_AMBER}[ADB]{C_RESET} adb not found in PATH or standard SDK roots.")

    if emulator_bin:
        print(f"{C_EMERALD}[EMULATOR]{C_RESET} Found emulator at: {emulator_bin}")
    else:
        print(f"{C_AMBER}[EMULATOR]{C_RESET} Android emulator binary not found in standard paths.")

    # Cleanup handler
    def cleanup_handler(signum, frame):
        print(f"\n{C_AMBER}[SHUTDOWN]{C_RESET} Stopping development containers and background processes...")
        subprocess.run(["podman", "stop", BACKEND_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if adb_bin:
            try:
                subprocess.run([adb_bin, "reverse", "--remove-all"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass
        print(f"{C_EMERALD}[SHUTDOWN]{C_RESET} Clean exit. Khoda-hafez!")
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup_handler)
    signal.signal(signal.SIGTERM, cleanup_handler)

    # Step 1: Start Backend
    if not args.emulator_only:
        if check_backend_health(args.port):
            print(f"{C_EMERALD}[BACKEND]{C_RESET} Backend is already running on port {args.port}.")
            shamsi = get_shamsi_today(args.port)
            if shamsi:
                print(f"{C_GOLD}[CALENDAR]{C_RESET} Tehran Shamsi Date: {shamsi}")
        else:
            start_backend_service(port=args.port)

    if args.backend_only:
        print(f"\n{C_EMERALD}[READY]{C_RESET} Backend is running at http://127.0.0.1:{args.port}. Press Ctrl+C to terminate.")
        while True:
            time.sleep(1)

    # Step 2: Android Emulator Setup
    print(f"\n{C_CYAN}[ANDROID]{C_RESET} Checking Android emulator status on Fedora...")

    running_devices = get_running_devices(adb_bin)
    emulator_device = None
    for d in running_devices:
        if d.startswith("emulator-"):
            emulator_device = d
            break

    if emulator_device:
        print(f"{C_EMERALD}[DEVICE]{C_RESET} Active Android emulator detected: {C_BOLD}{emulator_device}{C_RESET}")
    else:
        avds = list_configured_avds(emulator_bin)
        if not emulator_bin or not avds:
            print_fedora_android_setup_guide()
            print(f"{C_MUTED}[INFO]{C_RESET} Backend is active on port {args.port}. You can test API or Flutter mobile web/desktop.")
            print(f"{C_BOLD}[TIPS]{C_RESET} Run: 'cd mobile && flutter run -d linux' or 'flutter run -d chrome'")
            print(f"\n{C_EMERALD}[RUNNING]{C_RESET} Backend live at http://127.0.0.1:{args.port}. Press Ctrl+C to stop.")
            while True:
                time.sleep(1)

        target_avd = args.avd if args.avd else avds[0]
        print(f"{C_CYAN}[LAUNCH]{C_RESET} Booting Android AVD: {C_BOLD}{target_avd}{C_RESET} with KVM hardware acceleration...")

        emu_cmd = [emulator_bin, "-avd", target_avd, "-accel", "on", "-gpu", "host"]
        subprocess.Popen(emu_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        print(f"{C_MUTED}[WAIT]{C_RESET} Waiting for Android emulator to finish booting...", end="", flush=True)
        start_t = time.time()
        while time.time() - start_t < args.timeout:
            time.sleep(3)
            print(".", end="", flush=True)
            devices = get_running_devices(adb_bin)
            for d in devices:
                if d.startswith("emulator-"):
                    # Check boot complete
                    res = subprocess.run([adb_bin, "-s", d, "shell", "getprop", "sys.boot_completed"], stdout=subprocess.PIPE, text=True)
                    if res.stdout.strip() == "1":
                        emulator_device = d
                        print(f" {C_EMERALD}BOOT COMPLETE ({d}){C_RESET}")
                        break
            if emulator_device:
                break

        if not emulator_device:
            print(f" {C_AMBER}TIMEOUT{C_RESET}")
            print(f"{C_AMBER}[WARN]{C_RESET} Emulator is still starting up. It will appear once finished.")

    # Step 3: Reverse Port Forwarding for Android
    if emulator_device and adb_bin:
        print(f"{C_CYAN}[PORT-FORWARD]{C_RESET} Configuring adb reverse tcp:{args.port} -> tcp:{args.port} for emulator...")
        try:
            subprocess.run([adb_bin, "-s", emulator_device, "reverse", f"tcp:{args.port}", f"tcp:{args.port}"], check=True)
            print(f"{C_EMERALD}[PORT-FORWARD]{C_RESET} Successfully mapped. Android app can connect to http://127.0.0.1:{args.port} or http://10.0.2.2:{args.port}!")
        except Exception as e:
            print(f"{C_AMBER}[PORT-FORWARD]{C_RESET} Warning: adb reverse failed: {e}")

    # Step 4: Flutter Mobile Client launch
    flutter_bin = shutil.which("flutter")
    if flutter_bin:
        print(f"{C_CYAN}[MOBILE]{C_RESET} Launching Flutter mobile app on {emulator_device or 'emulator'}...")
        target_flag = ["-d", emulator_device] if emulator_device else []
        flutter_cmd = [flutter_bin, "run"] + target_flag
        subprocess.run(flutter_cmd, cwd="mobile")
    else:
        print(f"\n{C_GOLD}[PRODUCT READY]{C_RESET}")
        print(f"  • Backend Server: {C_BOLD}http://127.0.0.1:{args.port}{C_RESET}")
        print(f"  • Android Emulator Port Mapping: {C_BOLD}tcp:{args.port} -> tcp:{args.port}{C_RESET}")
        print(f"  • To run Flutter client: {C_BOLD}cd mobile && flutter run{C_RESET}")
        print(f"\nPress Ctrl+C to terminate services.")
        while True:
            time.sleep(1)


if __name__ == "__main__":
    main()
