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
PODMAN_ANDROID_CONTAINER_NAME = "smart-bubble-android-emulator"
DEFAULT_BACKEND_PORT = 8080


def print_banner():
    banner = f"""{C_GOLD}{C_BOLD}
========================================================================
  SMART BUBBLE CALC // سامانه حباب سنج و نبض بازار
  Compact Local Development & Android Product Runner (Fedora Linux)
========================================================================{C_RESET}
"""
    print(banner)


def check_kvm() -> bool:
    """Checks whether hardware virtualization (/dev/kvm) is available on Fedora."""
    kvm_path = "/dev/kvm"
    if os.path.exists(kvm_path):
        is_writable = os.access(kvm_path, os.R_OK | os.W_OK)
        if is_writable:
            print(f"{C_EMERALD}[KVM]{C_RESET} Hardware virtualization (/dev/kvm) is active and accessible.")
            return True
        else:
            print(f"{C_AMBER}[KVM]{C_RESET} /dev/kvm exists but requires group permission: sudo usermod -aG kvm $USER")
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
    """Starts the backend service using Podman container."""
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


def start_podman_android_emulator() -> bool:
    """Launches a lightweight containerized Android emulator via Podman with noVNC web display."""
    print(f"\n{C_CYAN}[PODMAN-ANDROID]{C_RESET} Launching containerized Android emulator with KVM acceleration...")
    # Check if already running
    chk = subprocess.run(["podman", "ps", "--filter", f"name={PODMAN_ANDROID_CONTAINER_NAME}", "--format", "{{.Names}}"], stdout=subprocess.PIPE, text=True)
    if PODMAN_ANDROID_CONTAINER_NAME in chk.stdout:
        print(f"{C_EMERALD}[PODMAN-ANDROID]{C_RESET} Container '{PODMAN_ANDROID_CONTAINER_NAME}' is already active.")
        print(f"{C_GOLD}[WEB-DISPLAY]{C_RESET} Open your browser at: {C_BOLD}http://127.0.0.1:6080{C_RESET} to view/control the device.")
        return True

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
        print(f"{C_EMERALD}[PODMAN-ANDROID]{C_RESET} Emulator container started successfully!")
        print(f"{C_GOLD}[WEB-DISPLAY]{C_RESET} Open: {C_BOLD}http://127.0.0.1:6080{C_RESET} (noVNC web viewer)")
        print(f"{C_MUTED}[ADB-CONNECT]{C_RESET} Run: 'adb connect 127.0.0.1:5555'")
        return True
    except Exception as e:
        print(f"{C_CORAL}[PODMAN-ANDROID]{C_RESET} Failed to start container: {e}")
        return False


def print_fedora_compact_android_guide():
    """Prints lightweight, compact alternatives to heavy Android Studio for Fedora developers."""
    guide = f"""
{C_AMBER}{C_BOLD}[LIGHTWEIGHT & COMPACT ANDROID TESTING OPTIONS FOR FEDORA]{C_RESET}
You do NOT need the heavy 4GB Android Studio IDE! Choose one of these 3 compact solutions:

{C_GOLD}{C_BOLD}Solution 1: Containerized Android with Podman (Zero Host SDK Bloat){C_RESET}
Run a full Android emulator inside Podman with KVM acceleration and view it in your browser:
  {C_CYAN}pnpm dev:all --podman-android{C_RESET}
  View and control screen live at: {C_BOLD}http://127.0.0.1:6080{C_RESET} (noVNC Web Interface)

{C_GOLD}{C_BOLD}Solution 2: Physical Android Device + scrcpy (Fastest & Lightest: 15MB total){C_RESET}
Plug any Android phone into USB with USB Debugging enabled:
  {C_CYAN}sudo dnf install -y scrcpy android-tools{C_RESET}
  {C_CYAN}scrcpy{C_RESET}
  (120 FPS hardware-accelerated screen mirror directly on KDE Plasma desktop with 0% CPU overhead)

{C_GOLD}{C_BOLD}Solution 3: Minimal CLI-only Android Tools (No Android Studio GUI, ~130MB){C_RESET}
Download only Google's command line tools to ~/Android/Sdk without the heavy IDE:
  {C_CYAN}sudo dnf install -y android-tools java-17-openjdk-devel{C_RESET}
  Run: {C_CYAN}emulator -avd <your_avd> -accel on{C_RESET}

{C_GOLD}{C_BOLD}Solution 4: Flutter Native Linux Desktop or Web (Instant 0-second testing){C_RESET}
Test the exact same code natively on Fedora without any Android emulation:
  {C_CYAN}cd mobile && flutter run -d linux{C_RESET}
  or
  {C_CYAN}cd mobile && flutter run -d chrome{C_RESET}
"""
    print(guide)


def main():
    parser = argparse.ArgumentParser(description="Smart-Bubble-Calc compact local development runner for Fedora")
    parser.add_argument("--port", type=int, default=DEFAULT_BACKEND_PORT, help="Backend port (default: 8080)")
    parser.add_argument("--backend-only", action="store_true", help="Start only backend service")
    parser.add_argument("--emulator-only", action="store_true", help="Start only Android emulator")
    parser.add_argument("--podman-android", action="store_true", help="Run containerized Android emulator via Podman with noVNC web display")
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
        print(f"{C_AMBER}[ADB]{C_RESET} adb not found on host. (Can be installed via: sudo dnf install -y android-tools)")

    if emulator_bin:
        print(f"{C_EMERALD}[EMULATOR]{C_RESET} Found emulator binary at: {emulator_bin}")

    # Cleanup handler
    def cleanup_handler(signum, frame):
        print(f"\n{C_AMBER}[SHUTDOWN]{C_RESET} Stopping development containers and background processes...")
        subprocess.run(["podman", "stop", BACKEND_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if args.podman_android:
            subprocess.run(["podman", "stop", PODMAN_ANDROID_CONTAINER_NAME], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
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

    # Step 2: Podman Containerized Android Emulator Mode
    if args.podman_android:
        start_podman_android_emulator()
        if adb_bin:
            time.sleep(2)
            subprocess.run([adb_bin, "connect", "127.0.0.1:5555"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run([adb_bin, "-s", "127.0.0.1:5555", "reverse", f"tcp:{args.port}", f"tcp:{args.port}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"\n{C_GOLD}[PRODUCT READY (PODMAN ANDROID)]{C_RESET}")
        print(f"  • Backend Server: {C_BOLD}http://127.0.0.1:{args.port}{C_RESET}")
        print(f"  • Web Emulator Display: {C_BOLD}http://127.0.0.1:6080{C_RESET}")
        print(f"  • ADB Endpoint: {C_BOLD}127.0.0.1:5555{C_RESET}")
        print(f"\nPress Ctrl+C to terminate services.")
        while True:
            time.sleep(1)

    # Step 3: Check standard or physical devices
    print(f"\n{C_CYAN}[DEVICE-SCAN]{C_RESET} Checking for connected Android devices or emulators...")

    running_devices = get_running_devices(adb_bin)
    active_device = running_devices[0] if running_devices else None

    if active_device:
        print(f"{C_EMERALD}[DEVICE]{C_RESET} Active device detected: {C_BOLD}{active_device}{C_RESET}")
    else:
        avds = list_configured_avds(emulator_bin)
        if not emulator_bin or not avds:
            print_fedora_compact_android_guide()
            print(f"{C_MUTED}[INFO]{C_RESET} Backend is active on port {args.port}.")
            print(f"\n{C_EMERALD}[RUNNING]{C_RESET} Backend live at http://127.0.0.1:{args.port}. Press Ctrl+C to stop.")
            while True:
                time.sleep(1)

        target_avd = args.avd if args.avd else avds[0]
        print(f"{C_CYAN}[LAUNCH]{C_RESET} Booting native Android AVD: {C_BOLD}{target_avd}{C_RESET} with KVM hardware acceleration...")

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
                    res = subprocess.run([adb_bin, "-s", d, "shell", "getprop", "sys.boot_completed"], stdout=subprocess.PIPE, text=True)
                    if res.stdout.strip() == "1":
                        active_device = d
                        print(f" {C_EMERALD}BOOT COMPLETE ({d}){C_RESET}")
                        break
            if active_device:
                break

    # Step 4: Reverse Port Forwarding for Android
    if active_device and adb_bin:
        print(f"{C_CYAN}[PORT-FORWARD]{C_RESET} Configuring adb reverse tcp:{args.port} -> tcp:{args.port} for {active_device}...")
        try:
            subprocess.run([adb_bin, "-s", active_device, "reverse", f"tcp:{args.port}", f"tcp:{args.port}"], check=True)
            print(f"{C_EMERALD}[PORT-FORWARD]{C_RESET} Successfully mapped. Android app connects to http://127.0.0.1:{args.port} or http://10.0.2.2:{args.port}!")
        except Exception as e:
            print(f"{C_AMBER}[PORT-FORWARD]{C_RESET} Warning: adb reverse failed: {e}")

    # Step 5: Flutter Mobile Client launch
    flutter_bin = shutil.which("flutter")
    if flutter_bin:
        print(f"{C_CYAN}[MOBILE]{C_RESET} Launching Flutter mobile app on {active_device or 'default device'}...")
        target_flag = ["-d", active_device] if active_device else []
        flutter_cmd = [flutter_bin, "run"] + target_flag
        subprocess.run(flutter_cmd, cwd="mobile")
    else:
        print(f"\n{C_GOLD}[PRODUCT READY]{C_RESET}")
        print(f"  • Backend Server: {C_BOLD}http://127.0.0.1:{args.port}{C_RESET}")
        print(f"  • Android Device Port Mapping: {C_BOLD}tcp:{args.port} -> tcp:{args.port}{C_RESET}")
        print(f"  • To run Flutter client: {C_BOLD}cd mobile && flutter run{C_RESET}")
        print(f"\nPress Ctrl+C to terminate services.")
        while True:
            time.sleep(1)


if __name__ == "__main__":
    main()
