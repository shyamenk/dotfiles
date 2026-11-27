#!/usr/bin/env python3
"""Control a Nothing CMF Buds Pro 2 over its RFCOMM control channel.

Usage:
  cmfbuds.py status [--addr ADDR]       battery and noise control
  cmfbuds.py settings [--addr ADDR]     status plus equalizer, bass and gestures
  cmfbuds.py anc MODE
  cmfbuds.py eq PRESET
  cmfbuds.py bass on|off|LEVEL          LEVEL is 0-5
  cmfbuds.py gesture SIDE TYPE ACTION

Always prints one JSON object on stdout so the shell plugin can parse it.
Protocol notes: the frame layout and command ids follow the Nothing X
protocol as documented by the EarA-linux project and confirmed on a real
CMF Buds Pro 2 (firmware 0.0.8.8).
"""

import json
import os
import socket
import struct
import subprocess
import sys
import time
import uuid
from typing import Iterator, Optional

SOF = 0x55
CTRL_WITH_CRC = 0x0160
NTAPP_UUID = uuid.UUID("aeac4a03-dff5-498f-843a-34487cf133eb")
DEVICE_NAME_HINT = "CMF Buds Pro 2"

CMD_BATTERY = 0x07
CMD_GESTURE_SET = 0x03
CMD_ANC_SET = 0x0F
CMD_EQ_SET = 0x10
CMD_GESTURE_GET = 0x18
CMD_ANC_GET = 0x1E
CMD_EQ_GET = 0x1F
CMD_BASS_GET = 0x4E
CMD_BASS_SET = 0x51
DIR_GET = 0xC0
DIR_SET = 0xF0
DIR_RESPONSE = 0x40
DIR_ACK = 0x70

ANC_MODES = {
    "high": 1,
    "mid": 2,
    "low": 3,
    "adaptive": 4,
    "off": 5,
    "transparency": 7,
}
ANC_FROM_WIRE = {v: k for k, v in ANC_MODES.items()}
BATTERY_COMPONENTS = {2: "left", 3: "right", 4: "case"}

# Preset 4 ("custom") needs a band editor and is not exposed yet.
EQ_PRESETS = {"balanced": 0, "more_bass": 1, "more_treble": 2, "voice": 3}
EQ_FROM_WIRE = {**{v: k for k, v in EQ_PRESETS.items()}, 4: "custom"}

GESTURE_SIDES = {"left": 0x02, "right": 0x03}
GESTURE_TYPES = {"double-pinch": 0x02, "triple-pinch": 0x03, "pinch-hold": 0x07, "double-pinch-hold": 0x09}
GESTURE_ACTIONS = {
    "no-action": 0x01,
    "skip-back": 0x08,
    "skip-forward": 0x09,
    "voice-assistant": 0x0B,
    "volume-up": 0x12,
    "volume-down": 0x13,
    "noise-control": 0x16,
    "noise-control-off-anc": 0x14,
    "noise-control-trans-off": 0x15,
    "noise-control-cycle": 0x0A,
}
GESTURE_SIDE_FROM_WIRE = {v: k for k, v in GESTURE_SIDES.items()}
GESTURE_TYPE_FROM_WIRE = {v: k for k, v in GESTURE_TYPES.items()}
GESTURE_ACTION_FROM_WIRE = {v: k for k, v in GESTURE_ACTIONS.items()}


def crc16_arc(data: bytes) -> int:
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return crc & 0xFFFF


def build_frame(command: int, direction: int, payload: bytes = b"", seq: int = 1) -> bytes:
    body = struct.pack("<BHHH", SOF, CTRL_WITH_CRC, command | (direction << 8), len(payload))
    body += bytes([seq]) + payload
    return body + struct.pack("<H", crc16_arc(body))


def parse_frames(buf: bytearray) -> Iterator[tuple[int, int, bytes]]:
    """Yield (command, direction, payload) for each complete, CRC-valid frame."""
    while True:
        start = buf.find(bytes([SOF]))
        if start < 0:
            buf.clear()
            return
        del buf[:start]
        if len(buf) < 8:
            return
        _sof, ctrl, wire, length = struct.unpack_from("<BHHH", buf)
        total = 8 + length + (2 if ctrl & 0x20 else 0)
        if len(buf) < total:
            return
        raw = bytes(buf[:total])
        del buf[:total]
        if ctrl & 0x20 and crc16_arc(raw[:-2]) != struct.unpack_from("<H", raw, total - 2)[0]:
            continue
        yield wire & 0xFF, wire >> 8, raw[8 : 8 + length]


def parse_battery(payload: bytes) -> dict:
    """Payload is a count followed by (component, value) pairs; bit 7 = charging."""
    out: dict = {}
    if not payload:
        return out
    for i in range(payload[0]):
        offset = 1 + i * 2
        if offset + 1 >= len(payload):
            break
        name = BATTERY_COMPONENTS.get(payload[offset])
        level = payload[offset + 1] & 0x7F
        if name and level <= 100:
            out[name] = {"level": level, "charging": bool(payload[offset + 1] & 0x80)}
    return out


def parse_anc(payload: bytes) -> Optional[str]:
    """Payload is (kind, value, 0) triplets; kind 1 carries the noise-control mode."""
    for offset in range(0, len(payload) - 1, 3):
        if payload[offset] == 1:
            return ANC_FROM_WIRE.get(payload[offset + 1], "unknown")
    return None


def parse_eq(payload: bytes) -> Optional[str]:
    return EQ_FROM_WIRE.get(payload[0], f"unknown-{payload[0]}") if payload else None


def parse_bass(payload: bytes) -> dict:
    """Payload is (enabled, level*2); level runs 0-5 in half steps."""
    if len(payload) < 2:
        return {"enabled": False, "level": 0.0}
    return {"enabled": bool(payload[0]), "level": payload[1] / 2}


def parse_gestures(payload: bytes) -> dict:
    """Payload is a count then (device, 1, type, action) quads; devices 2/3 are left/right."""
    out: dict = {"left": {}, "right": {}}
    for i in range(payload[0] if payload else 0):
        offset = 1 + i * 4
        if offset + 3 >= len(payload):
            break
        side = GESTURE_SIDE_FROM_WIRE.get(payload[offset])
        gesture = GESTURE_TYPE_FROM_WIRE.get(payload[offset + 2])
        if side and gesture:
            action = payload[offset + 3]
            out[side][gesture] = GESTURE_ACTION_FROM_WIRE.get(action, f"unknown-{action:#04x}")
    return out


def sdp_rfcomm_channel(address: str, service: uuid.UUID, timeout: float = 8) -> int:
    """Ask the device's SDP server which RFCOMM channel a 128-bit service uses."""
    sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)
    sock.settimeout(timeout)
    try:
        sock.connect((address, 1))
        pattern = b"\x35\x11\x1c" + service.bytes
        params = pattern + struct.pack(">H", 0xFFFF) + b"\x35\x05\x0a\x00\x00\xff\xff" + b"\x00"
        sock.send(struct.pack(">BHH", 0x06, 1, len(params)) + params)
        reply = sock.recv(65535)
    finally:
        sock.close()
    marker = reply.find(b"\x19\x00\x03\x08")  # protocol RFCOMM, then uint8 channel
    if marker < 0:
        raise RuntimeError("control service not advertised by device")
    return reply[marker + 4]


def cached_channel(address: str) -> int:
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    path = os.path.join(runtime, f"cmfbuds-{address.replace(':', '')}.channel")
    try:
        with open(path) as handle:
            return int(handle.read().strip())
    except (OSError, ValueError):
        pass
    channel = sdp_rfcomm_channel(address, NTAPP_UUID)
    try:
        with open(path, "w") as handle:
            handle.write(str(channel))
    except OSError:
        pass
    return channel


def find_connected_buds() -> Optional[str]:
    out = subprocess.run(
        ["bluetoothctl", "devices", "Connected"],
        capture_output=True, text=True, timeout=5, check=False,
    ).stdout
    for line in out.splitlines():
        parts = line.split(" ", 2)
        if len(parts) == 3 and DEVICE_NAME_HINT.lower() in parts[2].lower():
            return parts[1]
    return None


class Link:
    """One RFCOMM session to the buds; requests are matched by command id."""

    def __init__(self, address: str) -> None:
        self.sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
        self.sock.settimeout(6)
        self.sock.connect((address, cached_channel(address)))
        self.buf = bytearray()

    def close(self) -> None:
        self.sock.close()

    def request(self, command: int, direction: int, payload: bytes = b"", wait: float = 3.0) -> bytes:
        self.sock.send(build_frame(command, direction, payload))
        deadline = time.monotonic() + wait
        while time.monotonic() < deadline:
            self.sock.settimeout(max(0.1, deadline - time.monotonic()))
            try:
                self.buf.extend(self.sock.recv(4096))
            except socket.timeout:
                break
            for cmd, frame_dir, body in parse_frames(self.buf):
                if cmd == command and frame_dir in (DIR_RESPONSE, DIR_ACK):
                    return body
        raise TimeoutError(f"no reply to command 0x{command:02x}")

    def read_status(self) -> dict:
        battery = parse_battery(self.request(CMD_BATTERY, DIR_GET))
        anc = parse_anc(self.request(CMD_ANC_GET, DIR_GET))
        return {"battery": battery, "anc": anc}

    def read_settings(self) -> dict:
        return {
            "eq": parse_eq(self.request(CMD_EQ_GET, DIR_GET)),
            "bass": parse_bass(self.request(CMD_BASS_GET, DIR_GET)),
            "gestures": parse_gestures(self.request(CMD_GESTURE_GET, DIR_GET)),
        }

    def set_anc(self, mode: str) -> None:
        self.request(CMD_ANC_SET, DIR_SET, bytes([1, ANC_MODES[mode], 0]))

    def set_eq(self, preset: str) -> None:
        self.request(CMD_EQ_SET, DIR_SET, bytes([EQ_PRESETS[preset], 0]))

    def set_bass(self, enabled: bool, level: float) -> None:
        self.request(CMD_BASS_SET, DIR_SET, bytes([1 if enabled else 0, int(level * 2)]))

    def set_gesture(self, side: str, gesture: str, action: str) -> None:
        payload = bytes([1, GESTURE_SIDES[side], 1, GESTURE_TYPES[gesture], GESTURE_ACTIONS[action]])
        self.request(CMD_GESTURE_SET, DIR_SET, payload)


def parse_bass_args(value: str, current: dict) -> tuple[bool, float]:
    if value == "on":
        return True, current["level"] or 3.0
    if value == "off":
        return False, current["level"]
    level = float(value)
    if not 0 <= level <= 5:
        raise ValueError("bass level must be between 0 and 5")
    return level > 0, level


def apply_command(link: Link, command: str, args: list[str]) -> bool:
    """Run a write command; return True if settings should be re-read afterwards."""
    if command == "anc":
        link.set_anc(args[0])
        return False
    if command == "eq":
        link.set_eq(args[0])
    elif command == "bass":
        enabled, level = parse_bass_args(args[0], parse_bass(link.request(CMD_BASS_GET, DIR_GET)))
        link.set_bass(enabled, level)
    elif command == "gesture":
        link.set_gesture(*args)
    return True


def validate(command: str, args: list[str]) -> Optional[str]:
    choices = {
        "anc": [list(ANC_MODES)],
        "eq": [list(EQ_PRESETS)],
        "gesture": [list(GESTURE_SIDES), list(GESTURE_TYPES), list(GESTURE_ACTIONS)],
    }
    if command in ("status", "settings"):
        return None
    if command == "bass":
        return None if len(args) == 1 else "bass takes one argument: on, off or 0-5"
    if command not in choices:
        return f"unknown command: {command}"
    if len(args) != len(choices[command]):
        return f"{command} takes {len(choices[command])} argument(s)"
    for value, allowed in zip(args, choices[command]):
        if value not in allowed:
            return f"{value!r} is not valid; use one of: {', '.join(allowed)}"
    return None


def run(argv: list[str]) -> dict:
    args = list(argv)
    address = None
    if "--addr" in args:
        i = args.index("--addr")
        address = args[i + 1]
        del args[i : i + 2]
    command, rest = (args[0], args[1:]) if args else ("status", [])

    problem = validate(command, rest)
    if problem:
        return {"connected": False, "error": problem}

    address = address or find_connected_buds()
    if not address:
        return {"connected": False, "error": "no connected CMF Buds Pro 2"}

    link = None
    try:
        link = Link(address)
        reread = command == "settings"
        if command in ("anc", "eq", "bass", "gesture"):
            reread = apply_command(link, command, rest)
            time.sleep(0.3)
        result = {"connected": True, "address": address, **link.read_status()}
        if reread:
            result.update(link.read_settings())
        return result
    except (OSError, TimeoutError, RuntimeError, ValueError) as exc:
        return {"connected": False, "address": address, "error": str(exc)}
    finally:
        if link:
            link.close()


if __name__ == "__main__":
    result = run(sys.argv[1:])
    print(json.dumps(result))
    sys.exit(0 if result.get("connected") else 1)
