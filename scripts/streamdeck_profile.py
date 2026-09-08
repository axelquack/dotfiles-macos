#!/usr/bin/env python3
"""Write Elgato Stream Deck ProfilesV3 pages for a 15-key MK.2 + MCP Deck.

The Elgato app keeps profiles in memory and overwrites disk on quit.
Callers must quit the app, run this, then relaunch (see streamdeck-apply.sh).

Public repo: no serials, LAN IPs, or secrets in the generated JSON.
"""
from __future__ import annotations

import argparse
import json
import shlex
import shutil
import struct
import subprocess
import sys
import uuid
import zlib
from dataclasses import dataclass
from pathlib import Path

ICON = 144  # Stream Deck MK.2 key artwork is 144×144 PNG

# Stable page IDs so re-apply is idempotent (lowercase in JSON, uppercase dirs).
PAGE_HOME = "c0de0001-a11e-4e11-b0b0-000000000001"
PAGE_APPS = "c0de0001-a11e-4e11-b0b0-000000000002"
PAGE_OPS = "c0de0001-a11e-4e11-b0b0-000000000003"
PAGE_STUDIO = "c0de0001-a11e-4e11-b0b0-000000000004"
PAGE_GIT = "c0de0001-a11e-4e11-b0b0-000000000005"
PAGE_TWO = "c0de0001-a11e-4e11-b0b0-000000000006"
PAGE_MCP = "c0de0001-a11e-4e11-b0b0-000000000010"

# Tokyo Night-ish palette (matches Grok TUI theme in this repo).
C_BG = (26, 27, 38, 255)
C_BLUE = (122, 162, 247, 255)
C_CYAN = (125, 207, 255, 255)
C_MAGENTA = (187, 154, 247, 255)
C_GREEN = (158, 206, 106, 255)
C_YELLOW = (224, 175, 104, 255)
C_ORANGE = (255, 158, 100, 255)
C_RED = (247, 118, 142, 255)
C_DIM = (86, 95, 137, 255)
C_WHITE = (192, 202, 245, 255)
C_BLACK = (0, 0, 0, 0)

# 5×7 bitmap font (A–Z, 0–9, space, plus a few symbols). Rows are top→bottom.
_FONT: dict[str, tuple[str, ...]] = {
    " ": ("00000",) * 7,
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "10001", "11110", "10001", "10001", "11110"),
    "C": ("01110", "10001", "10000", "10000", "10000", "10001", "01110"),
    "D": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "F": ("11111", "10000", "10000", "11110", "10000", "10000", "10000"),
    "G": ("01110", "10001", "10000", "10111", "10001", "10001", "01110"),
    "H": ("10001", "10001", "10001", "11111", "10001", "10001", "10001"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "J": ("00111", "00010", "00010", "00010", "00010", "10010", "01100"),
    "K": ("10001", "10010", "10100", "11000", "10100", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "Q": ("01110", "10001", "10001", "10001", "10101", "10010", "01101"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "10001", "10001", "01110"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "10101", "01010"),
    "X": ("10001", "10001", "01010", "00100", "01010", "10001", "10001"),
    "Y": ("10001", "10001", "01010", "00100", "00100", "00100", "00100"),
    "Z": ("11111", "00001", "00010", "00100", "01000", "10000", "11111"),
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
    "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
    "3": ("11110", "00001", "00001", "01110", "00001", "00001", "11110"),
    "4": ("00010", "00110", "01010", "10010", "11111", "00010", "00010"),
    "5": ("11111", "10000", "11110", "00001", "00001", "10001", "01110"),
    "6": ("01110", "10000", "11110", "10001", "10001", "10001", "01110"),
    "7": ("11111", "00001", "00010", "00100", "01000", "01000", "01000"),
    "8": ("01110", "10001", "10001", "01110", "10001", "10001", "01110"),
    "9": ("01110", "10001", "10001", "01111", "00001", "00001", "01110"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    "+": ("00000", "00100", "00100", "11111", "00100", "00100", "00000"),
    "/": ("00001", "00010", "00010", "00100", "01000", "01000", "10000"),
    ".": ("00000", "00000", "00000", "00000", "00000", "01100", "01100"),
}

# macOS virtual key codes for digit row (same on ANSI/ISO German for 0–9).
DIGIT_NATIVE = {
    "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
    "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
}
DIGIT_QT = {str(i): 48 + i for i in range(10)}

# Elgato KeyModifiers bitmask: Shift=1 Ctrl=2 Option=4 Cmd=8
MOD_SHIFT, MOD_CTRL, MOD_OPTION, MOD_CMD = 1, 2, 4, 8

PROFILES_V3 = Path.home() / "Library/Application Support/com.elgato.StreamDeck/ProfilesV3"
BIN = Path.home() / ".config/streamdeck/bin"
APPS_DIR = Path.home() / ".config/streamdeck/apps"
ICON_BIN = BIN / "streamdeck-icon"
ICON_CACHE = Path.home() / ".config/streamdeck/cache"
HW_MODEL = "20GAA9902"  # Stream Deck MK.2
MCP_MODEL = "AI Stream Deck"  # virtual 8×4 MCP Deck (XL-sized)
ELGATO_STATIC = (
    Path.home()
    / "Library/Application Support/com.elgato.StreamDeck"
    / "Plugins/com.elgato.keycreator.sdPlugin/static"
)
PACK_ICON_WHITE = ELGATO_STATIC / "com.elgato.defaulticonswhite.sdIconPack" / "icons"
PACK_LOGO_WHITE = ELGATO_STATIC / "com.elgato.logoiconswhite.sdIconPack" / "icons"


def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_png(path: Path, pixels: list[tuple[int, int, int, int]], w: int, h: int) -> None:
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw.extend(pixels[y * w + x])
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + _chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def _blend(dst: list[tuple[int, int, int, int]], x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < ICON and 0 <= y < ICON:
        dst[y * ICON + x] = color


def _fill_round_rect(
    pix: list[tuple[int, int, int, int]],
    color: tuple[int, int, int, int],
    margin: int = 8,
    radius: int = 22,
) -> None:
    x0, y0, x1, y1 = margin, margin, ICON - 1 - margin, ICON - 1 - margin
    r2 = radius * radius
    for y in range(ICON):
        for x in range(ICON):
            if x < x0 or x > x1 or y < y0 or y > y1:
                continue
            cx = x0 + radius if x < x0 + radius else (x1 - radius if x > x1 - radius else x)
            cy = y0 + radius if y < y0 + radius else (y1 - radius if y > y1 - radius else y)
            if x < x0 + radius or x > x1 - radius or y < y0 + radius or y > y1 - radius:
                dx, dy = x - cx, y - cy
                if dx * dx + dy * dy > r2:
                    continue
            pix[y * ICON + x] = color


def _draw_text(
    pix: list[tuple[int, int, int, int]],
    text: str,
    cy: int,
    color: tuple[int, int, int, int],
    scale: int = 3,
) -> None:
    text = text.upper()
    cw, ch = 5 * scale, 7 * scale
    gap = scale
    width = len(text) * cw + max(0, len(text) - 1) * gap
    x0 = (ICON - width) // 2
    y0 = cy - ch // 2
    for i, ch_ in enumerate(text):
        glyph = _FONT.get(ch_, _FONT[" "])
        ox = x0 + i * (cw + gap)
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit != "1":
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        _blend(pix, ox + gx * scale + sx, y0 + gy * scale + sy, color)


def make_icon(lines: list[str], fill: tuple[int, int, int, int]) -> list[tuple[int, int, int, int]]:
    pix = [C_BG] * (ICON * ICON)
    _fill_round_rect(pix, fill)
    n = len(lines)
    if n == 1:
        _draw_text(pix, lines[0], ICON // 2, C_BG, scale=3 if len(lines[0]) <= 5 else 2)
    else:
        _draw_text(pix, lines[0], ICON // 2 - 16, C_BG, scale=2)
        _draw_text(pix, lines[1], ICON // 2 + 16, C_BG, scale=2)
    return pix


def _img_name() -> str:
    return uuid.uuid4().hex[:24].upper() + "Z.png"


def _state(title: str, image: str, show: bool = False) -> dict:
    return {
        "FontFamily": "",
        "FontSize": 11,
        "FontStyle": "",
        "FontUnderline": False,
        "Image": f"Images/{image}",
        "OutlineThickness": 2,
        "ShowTitle": show,
        "Title": title,
        "TitleAlignment": "bottom",
        "TitleColor": "#ffffff",
    }


def _empty_hotkey_slot() -> dict:
    return {
        "KeyCmd": False,
        "KeyCtrl": False,
        "KeyModifiers": 0,
        "KeyOption": False,
        "KeyShift": False,
        "NativeCode": -1,
        "QTKeyCode": 33554431,
        "VKeyCode": -1,
    }


def action_hotkey_alt_cmd_digit(digit: str, title: str, image: str) -> dict:
    native = DIGIT_NATIVE[digit]
    qt = DIGIT_QT[digit]
    mods = MOD_OPTION | MOD_CMD
    slot = {
        "KeyCmd": True,
        "KeyCtrl": False,
        "KeyModifiers": mods,
        "KeyOption": True,
        "KeyShift": False,
        "NativeCode": native,
        "QTKeyCode": qt,
        "VKeyCode": native,
    }
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Hotkey",
        "Plugin": {
            "Name": "Activate a Key Command",
            "UUID": "com.elgato.streamdeck.system.hotkey",
            "Version": "1.0",
        },
        "Resources": None,
        "Settings": {"Coalesce": True, "Hotkeys": [slot, _empty_hotkey_slot(), _empty_hotkey_slot(), _empty_hotkey_slot()]},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.system.hotkey",
    }


def action_hotkey_cmd_shift_digit(digit: str, title: str, image: str) -> dict:
    native = DIGIT_NATIVE[digit]
    qt = DIGIT_QT[digit]
    mods = MOD_SHIFT | MOD_CMD
    slot = {
        "KeyCmd": True,
        "KeyCtrl": False,
        "KeyModifiers": mods,
        "KeyOption": False,
        "KeyShift": True,
        "NativeCode": native,
        "QTKeyCode": qt,
        "VKeyCode": native,
    }
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Hotkey",
        "Plugin": {
            "Name": "Activate a Key Command",
            "UUID": "com.elgato.streamdeck.system.hotkey",
            "Version": "1.0",
        },
        "Resources": None,
        "Settings": {"Coalesce": True, "Hotkeys": [slot, _empty_hotkey_slot(), _empty_hotkey_slot(), _empty_hotkey_slot()]},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.system.hotkey",
    }


def action_open(path: Path, title: str, image: str) -> dict:
    quoted = f'"{path}"'
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Open",
        "Plugin": {"Name": "Open", "UUID": "com.elgato.streamdeck.system.open", "Version": "1.0"},
        "Resources": None,
        "Settings": {"path": quoted},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.system.open",
    }


def action_website(url: str, title: str, image: str) -> dict:
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Website",
        "Plugin": {"Name": "Website", "UUID": "com.elgato.streamdeck.system.website", "Version": "1.0"},
        "Resources": None,
        "Settings": {"openInBrowser": True, "path": url},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.system.website",
    }


def action_folder(page_uuid: str, title: str, image: str) -> dict:
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Create Folder",
        "Plugin": {
            "Name": "Create Folder",
            "UUID": "com.elgato.streamdeck.profile.openchild",
            "Version": "1.0",
        },
        "Resources": None,
        "Settings": {"ProfileUUID": page_uuid.lower()},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.profile.openchild",
    }


def action_back(image: str) -> dict:
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Parent Folder",
        "Resources": None,
        "Settings": {},
        "State": 0,
        "States": [_state("Back", image)],
        "UUID": "com.elgato.streamdeck.profile.backtoparent",
    }


def action_page(direction: str, title: str, image: str) -> dict:
    """direction is 'previous' or 'next' (Elgato page swipe keys)."""
    name = "Previous Page" if direction == "previous" else "Next Page"
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": name,
        "Plugin": {"Name": "Pages", "UUID": "com.elgato.streamdeck.page", "Version": "1.0"},
        "Resources": None,
        "Settings": {},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": f"com.elgato.streamdeck.page.{direction}",
    }


def action_media(action_idx: int, title: str, image: str) -> dict:
    return {
        "ActionID": str(uuid.uuid4()),
        "LinkedTitle": True,
        "Name": "Multimedia",
        "Plugin": {
            "Name": "Multimedia",
            "UUID": "com.elgato.streamdeck.system.multimedia",
            "Version": "1.0",
        },
        "Resources": None,
        "Settings": {"actionIdx": action_idx},
        "State": 0,
        "States": [_state(title, image)],
        "UUID": "com.elgato.streamdeck.system.multimedia",
    }


@dataclass(frozen=True)
class IconSpec:
    label: str
    fill: tuple[int, int, int, int]
    pack: str | None = None
    symbol: str | None = None
    app_path: Path | None = None
    tint: bool | None = None


def I(
    label: str,
    fill: tuple[int, int, int, int],
    *,
    pack: str | None = None,
    symbol: str | None = None,
    app_path: Path | None = None,
    tint: bool | None = None,
) -> IconSpec:
    return IconSpec(label=label, fill=fill, pack=pack, symbol=symbol, app_path=app_path, tint=tint)


def accent_hex(fill: tuple[int, int, int, int]) -> str:
    return f"{fill[0]:02X}{fill[1]:02X}{fill[2]:02X}"


def resolve_pack(name: str) -> Path | None:
    for folder in (PACK_LOGO_WHITE, PACK_ICON_WHITE):
        candidate = folder / name
        if candidate.is_file():
            return candidate
    return None


def _which_rsvg() -> str | None:
    found = shutil.which("rsvg-convert")
    if found:
        return found
    for candidate in ("/opt/homebrew/bin/rsvg-convert", "/usr/local/bin/rsvg-convert"):
        if Path(candidate).is_file():
            return candidate
    return None


def rasterize_svg(src: Path) -> Path | None:
    if src.suffix.lower() == ".png":
        return src
    ICON_CACHE.mkdir(parents=True, exist_ok=True)
    dest = ICON_CACHE / f"{src.stem}.png"
    if dest.is_file() and dest.stat().st_mtime >= src.stat().st_mtime:
        return dest
    rsvg = _which_rsvg()
    if not rsvg:
        return None
    try:
        subprocess.run(
            [rsvg, "-w", "288", "-h", "288", "-b", "none", str(src), "-o", str(dest)],
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError:
        return None
    return dest if dest.is_file() else None


def render_icon(dest: Path, spec: IconSpec) -> bool:
    if not ICON_BIN.is_file():
        return False
    cmd = [
        str(ICON_BIN),
        "--out",
        str(dest),
        "--label",
        spec.label,
        "--accent",
        accent_hex(spec.fill),
    ]
    image: Path | None = None
    if spec.pack:
        pack = resolve_pack(spec.pack)
        if pack is not None:
            image = rasterize_svg(pack) if pack.suffix.lower() == ".svg" else pack
    if image is not None and image.is_file():
        cmd += ["--image", str(image)]
        use_tint = spec.tint
        if use_tint is None:
            use_tint = not spec.pack.startswith("Logo") if spec.pack else False
        if use_tint:
            cmd += ["--tint", "1"]
    elif spec.app_path is not None and Path(spec.app_path).exists():
        cmd += ["--app", str(spec.app_path)]
    elif spec.symbol:
        cmd += ["--symbol", spec.symbol]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        return False
    return dest.is_file() and dest.stat().st_size > 0


class PageWriter:
    def __init__(self, page_dir: Path) -> None:
        self.page_dir = page_dir
        self.images = page_dir / "Images"
        self.actions: dict[str, dict] = {}
        self.images.mkdir(parents=True, exist_ok=True)

    def add(self, col: int, row: int, action: dict, spec: IconSpec) -> None:
        img = _img_name()
        dest = self.images / img
        if not render_icon(dest, spec):
            write_png(dest, make_icon([spec.label], spec.fill), ICON, ICON)
        action["States"][0]["Image"] = f"Images/{img}"
        self.actions[f"{col},{row}"] = action

    def write(self, name: str = "") -> None:
        manifest = {
            "Controllers": [{"Actions": self.actions, "Type": "Keypad"}],
            "Icon": "",
            "Name": name,
        }
        (self.page_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def cmd(name: str) -> Path:
    return BIN / name


def app(name: str) -> Path:
    mac = Path("/Applications") / name
    sysapp = Path("/System/Applications") / name
    util = Path("/System/Applications/Utilities") / name
    core = Path("/System/Library/CoreServices") / name
    for cand in (mac, sysapp, util, core):
        if cand.exists():
            return cand
    return mac  # still bind; Open no-ops if missing (haumea vs moon)


def shell_app(name: str, script: str) -> Path:
    """Tiny LSUIElement applet so Stream Deck Open runs a shell command silently.

    Avoids Elgato hotkeys (those need Accessibility) and avoids .command Terminal flash.
    """
    dest = APPS_DIR / f"{name}.app"
    if dest.exists():
        shutil.rmtree(dest)
    APPS_DIR.mkdir(parents=True, exist_ok=True)
    esc = script.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(
        ["osacompile", "-o", str(dest), "-e", f'do shell script "{esc}"'],
        check=True,
        capture_output=True,
    )
    info = dest / "Contents" / "Info.plist"
    subprocess.run(
        ["plutil", "-replace", "LSUIElement", "-bool", "YES", str(info)],
        check=False,
        capture_output=True,
    )
    return dest


_WS_APPS: dict[str, Path] = {}
_HUE_APPS: dict[str, Path] = {}


def workspace_app(workspace: str) -> Path:
    if workspace in _WS_APPS:
        return _WS_APPS[workspace]
    script = (
        "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; "
        f"aerospace workspace {workspace}"
    )
    dest = shell_app(f"workspace-{workspace}", script)
    _WS_APPS[workspace] = dest
    return dest


def hue_app(action: str) -> Path:
    """Silent applet: hue-scene.sh SCENE  or  hue-scene.sh --off."""
    slug = "off" if action in ("--off", "off", "aus") else action.casefold()
    slug = "".join(ch if ch.isalnum() else "-" for ch in slug).strip("-") or "scene"
    if slug in _HUE_APPS:
        return _HUE_APPS[slug]
    helper = BIN / "hue-scene.sh"
    arg = "--off" if action in ("--off", "off", "aus") else action
    script = (
        "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; "
        f"{shlex.quote(str(helper))} {shlex.quote(arg)}"
    )
    dest = shell_app(f"hue-{slug}", script)
    _HUE_APPS[slug] = dest
    return dest


def icon_catalog() -> dict[str, IconSpec]:
    """Tokyo Night tiles + Elgato white pack / SF Symbols / app icons."""
    return {
        "web": I("WEB", C_BLUE, pack="IconGlobe-Filled-White.svg", symbol="globe"),
        "code": I("CODE", C_BLUE, pack="IconCode-White.svg", symbol="chevron.left.forwardslash.chevron.right"),
        "term": I("TERM", C_BLUE, pack="IconTerminal-Filled-White.svg", symbol="terminal.fill"),
        "comms": I("COMMS", C_BLUE, pack="IconMessage-Filled-White.svg", symbol="bubble.left.and.bubble.right.fill"),
        "docs": I("DOCS", C_BLUE, pack="IconFile-Filled-White.svg", symbol="doc.text.fill"),
        "media": I("MEDIA", C_DIM, pack="IconFilm-Filled-White.svg", symbol="play.rectangle.fill"),
        "files": I("FILES", C_DIM, pack="IconFolder-Filled-White.svg", symbol="folder.fill"),
        "games": I("GAMES", C_DIM, pack="IconGame-Filled-White.svg", symbol="gamecontroller.fill"),
        "design": I("DSGN", C_DIM, pack="IconPalette-Filled-White.svg", symbol="paintpalette.fill"),
        "vm": I("VM", C_DIM, pack="IconLaptop-Filled-White.svg", symbol="desktopcomputer"),
        "apps": I("APPS", C_MAGENTA, pack="IconApps-Filled-White.svg", symbol="square.grid.2x2.fill"),
        "ops": I("OPS", C_GREEN, pack="IconSettings-Filled-White.svg", symbol="gearshape.2.fill"),
        "studio": I("STUDIO", C_ORANGE, pack="IconCamera-Filled-White.svg", symbol="camera.fill"),
        "git": I("GIT", C_YELLOW, pack="LogoGithub-White.svg", symbol="arrow.triangle.branch", tint=False),
        "grok": I("GROK", C_CYAN, pack="LogoGrok-White.svg", symbol="sparkles", tint=False),
        "back": I("BACK", C_DIM, pack="IconFolderBack-Filled-White.svg", symbol="chevron.backward"),
        "prev": I("PREV", C_DIM, pack="IconArrowLeft-White.svg", symbol="chevron.left"),
        "next": I("NEXT", C_DIM, pack="IconArrowRight-White.svg", symbol="chevron.right"),
        "cursor": I("CURSOR", C_MAGENTA, pack="LogoCursor-White.svg", app_path=app("Cursor.app"), tint=False),
        "zed": I("ZED", C_MAGENTA, app_path=app("Zed.app"), symbol="chevron.left.forwardslash.chevron.right"),
        "opencode": I("OC", C_MAGENTA, app_path=app("OpenCode.app"), symbol="terminal.fill"),
        "claude": I("CLAUDE", C_MAGENTA, pack="LogoClaude-White.svg", app_path=app("Claude.app"), tint=False),
        "brave": I("BRAVE", C_ORANGE, pack="LogoBrave-White.svg", app_path=app("Brave Browser.app"), tint=False),
        "obsidian": I("OBS", C_MAGENTA, pack="LogoObsidian-White.svg", app_path=app("Obsidian.app"), tint=False),
        "mail": I("MAIL", C_BLUE, app_path=app("Mail.app"), symbol="envelope.fill"),
        "pass": I("PASS", C_GREEN, pack="IconKey-Filled-White.svg", symbol="key.fill"),
        "proton-pass": I("PASS", C_GREEN, app_path=app("Proton Pass.app"), symbol="key.fill"),
        "orb": I("ORB", C_CYAN, app_path=app("OrbStack.app"), symbol="shippingbox.fill"),
        "goose": I("GOOSE", C_YELLOW, app_path=app("Goose.app"), symbol="bird.fill"),
        "muffin": I("MUFFIN", C_BLUE, app_path=app("MuffinTerm.app"), symbol="terminal.fill"),
        "signal": I("SIGNAL", C_BLUE, app_path=app("Signal.app"), symbol="message.fill"),
        "cam": I("CAM", C_ORANGE, pack="LogoElgatoCameraHub-White.svg", app_path=app("Elgato Camera Hub.app"), tint=False),
        "light": I("LIGHT", C_ORANGE, pack="IconKeyLight-Filled-White.svg", app_path=app("Elgato Control Center.app"), symbol="light.max"),
        "apply": I("APPLY", C_GREEN, pack="IconSync-White.svg", symbol="arrow.triangle.2.circlepath"),
        "diff": I("DIFF", C_GREEN, symbol="plus.forwardslash.minus"),
        "secrets": I("SECRETS", C_RED, pack="IconShield-Filled-White.svg", symbol="lock.shield.fill"),
        "brew": I("BREW", C_YELLOW, pack="IconPackage-Filled-White.svg", symbol="shippingbox.fill"),
        "ssh": I("SSH", C_GREEN, pack="IconLock-Filled-White.svg", symbol="lock.fill"),
        "repo": I("REPO", C_CYAN, pack="IconFolderOpen-Filled-White.svg", symbol="folder.fill"),
        "himalaya": I("MAIL", C_BLUE, pack="IconMail-Filled-White.svg", symbol="envelope.fill"),
        "topg": I("TOPG", C_RED, pack="IconArrowUp-White.svg", symbol="arrow.up.circle.fill"),
        "nas": I("NAS", C_ORANGE, pack="IconServer-White.svg", symbol="externaldrive.fill"),
        "status": I("STATUS", C_GREEN, pack="IconCheckmarkCircle-Filled-White.svg", symbol="checkmark.circle.fill"),
        "aero": I("AERO", C_BLUE, pack="IconWindow-Filled-White.svg", symbol="rectangle.split.2x1"),
        "gh": I("GH", C_DIM, pack="LogoGithub-White.svg", symbol="arrow.triangle.branch", tint=False),
        "shot": I("SHOT", C_YELLOW, pack="IconScreenshot-White.svg", symbol="camera.viewfinder"),
        "rec": I("REC", C_RED, pack="IconRecord-Filled-White.svg", symbol="record.circle"),
        "mute": I("MUTE", C_RED, pack="IconVolumeMuted-Filled-White.svg", symbol="speaker.slash.fill"),
        "play": I("PLAY", C_GREEN, pack="IconPlay-Filled-White.svg", symbol="play.fill"),
        "vol-": I("VOL-", C_DIM, pack="IconVolume1-Filled-White.svg", symbol="speaker.minus.fill"),
        "vol+": I("VOL+", C_DIM, pack="IconVolume2-Filled-White.svg", symbol="speaker.plus.fill"),
        "roon": I("ROON", C_YELLOW, app_path=app("Roon.app"), symbol="music.note"),
        "hue-tokio": I("TOKIO", C_ORANGE, pack="IconCity-Filled-White.svg", symbol="building.2.fill"),
        "hue-lesen": I("LESEN", C_YELLOW, pack="IconBook-Filled-White.svg", symbol="book.fill"),
        "hue-pink": I("PINK", C_MAGENTA, pack="IconDroplet-Filled-White.svg", symbol="drop.fill"),
        "hue-nacht": I("DIM", C_DIM, pack="IconBrightnessDecrease-Filled-White.svg", symbol="moon.fill"),
        "hue-off": I("AUS", C_RED, pack="IconBrightnessOff-Filled-White.svg", symbol="lightswitch.off"),
        "git-status": I("STATUS", C_YELLOW, pack="IconCheckmarkCircle-Filled-White.svg", symbol="checkmark.circle.fill"),
        "pull": I("PULL", C_GREEN, pack="IconDownload-White.svg", symbol="arrow.down.to.line"),
        "push": I("PUSH", C_RED, pack="IconUpload-White.svg", symbol="arrow.up.to.line"),
        "log": I("LOG", C_YELLOW, pack="IconTimeHistory-White.svg", symbol="clock.arrow.circlepath"),
        "git-diff": I("DIFF", C_YELLOW, symbol="plus.forwardslash.minus"),
    }


def write_hardware_pages(profile_root: Path) -> None:
    pages = profile_root / "Profiles"
    if pages.exists():
        shutil.rmtree(pages)
    pages.mkdir(parents=True)
    ic = icon_catalog()

    home = PageWriter(pages / PAGE_HOME.upper())
    # Row 0 — AeroSpace workspaces (CLI applets; no Accessibility hotkeys)
    home.add(0, 0, action_open(workspace_app("web"), "web", "x"), ic["web"])
    home.add(1, 0, action_open(workspace_app("code"), "code", "x"), ic["code"])
    home.add(2, 0, action_open(workspace_app("term"), "term", "x"), ic["term"])
    home.add(3, 0, action_open(workspace_app("comms"), "comms", "x"), ic["comms"])
    home.add(4, 0, action_open(workspace_app("docs"), "docs", "x"), ic["docs"])
    # Row 1 — workspaces 6–0
    home.add(0, 1, action_open(workspace_app("media"), "media", "x"), ic["media"])
    home.add(1, 1, action_open(workspace_app("files"), "files", "x"), ic["files"])
    home.add(2, 1, action_open(workspace_app("games"), "games", "x"), ic["games"])
    home.add(3, 1, action_open(workspace_app("design"), "design", "x"), ic["design"])
    home.add(4, 1, action_open(workspace_app("vm"), "vm", "x"), ic["vm"])
    # Row 2 — folders + Grok
    home.add(0, 2, action_folder(PAGE_APPS, "Apps", "x"), ic["apps"])
    home.add(1, 2, action_folder(PAGE_OPS, "Ops", "x"), ic["ops"])
    home.add(2, 2, action_folder(PAGE_STUDIO, "Studio", "x"), ic["studio"])
    home.add(3, 2, action_folder(PAGE_GIT, "Git", "x"), ic["git"])
    home.add(4, 2, action_open(cmd("grok-tui.command"), "Grok", "x"), ic["grok"])
    home.write("Home")

    two = PageWriter(pages / PAGE_TWO.upper())
    # MCP keys that are not on hardware home (workspaces + folders + Grok).
    # 14 slots + Previous Page at 0,2 (where the extra screen already had it).
    two.add(0, 0, action_open(cmd("chezmoi-apply.command"), "Apply", "x"), ic["apply"])
    two.add(1, 0, action_open(cmd("chezmoi-diff.command"), "Diff", "x"), ic["diff"])
    two.add(2, 0, action_open(cmd("check-secrets.command"), "Secrets", "x"), ic["secrets"])
    two.add(3, 0, action_open(cmd("ansible-brew.command"), "Ansible", "x"), ic["brew"])
    two.add(4, 0, action_open(cmd("topgrade.command"), "Topgrade", "x"), ic["topg"])
    two.add(0, 1, action_open(cmd("chezmoi-status.command"), "Status", "x"), ic["status"])
    two.add(1, 1, action_open(cmd("aerospace-reload.command"), "Aero", "x"), ic["aero"])
    two.add(2, 1, action_open(cmd("mount-nas.command"), "NAS", "x"), ic["nas"])
    two.add(3, 1, action_open(app("Cursor.app"), "Cursor", "x"), ic["cursor"])
    two.add(4, 1, action_open(app("Zed.app"), "Zed", "x"), ic["zed"])
    two.add(0, 2, action_page("previous", "Prev", "x"), ic["prev"])
    two.add(1, 2, action_open(app("Obsidian.app"), "Obsidian", "x"), ic["obsidian"])
    two.add(2, 2, action_open(app("Brave Browser.app"), "Brave", "x"), ic["brave"])
    two.add(3, 2, action_open(app("Elgato Camera Hub.app"), "Cam Hub", "x"), ic["cam"])
    two.add(4, 2, action_open(app("Elgato Control Center.app"), "Lights", "x"), ic["light"])
    two.write("MCP")

    apps = PageWriter(pages / PAGE_APPS.upper())
    apps.add(0, 0, action_back("x"), ic["back"])
    apps.add(1, 0, action_open(app("Cursor.app"), "Cursor", "x"), ic["cursor"])
    apps.add(2, 0, action_open(app("Zed.app"), "Zed", "x"), ic["zed"])
    apps.add(3, 0, action_open(app("OpenCode.app"), "OpenCode", "x"), ic["opencode"])
    apps.add(4, 0, action_open(app("Claude.app"), "Claude", "x"), ic["claude"])
    apps.add(0, 1, action_open(app("Brave Browser.app"), "Brave", "x"), ic["brave"])
    apps.add(1, 1, action_open(app("Obsidian.app"), "Obsidian", "x"), ic["obsidian"])
    apps.add(2, 1, action_open(app("Mail.app"), "Mail", "x"), ic["mail"])
    apps.add(3, 1, action_open(app("Proton Pass.app"), "Pass", "x"), ic["proton-pass"])
    apps.add(4, 1, action_open(app("OrbStack.app"), "OrbStack", "x"), ic["orb"])
    apps.add(0, 2, action_open(app("Goose.app"), "Goose", "x"), ic["goose"])
    apps.add(1, 2, action_open(app("MuffinTerm.app"), "Term", "x"), ic["muffin"])
    apps.add(2, 2, action_open(app("Signal.app"), "Signal", "x"), ic["signal"])
    apps.add(3, 2, action_open(app("Elgato Camera Hub.app"), "Cam Hub", "x"), ic["cam"])
    apps.add(4, 2, action_open(app("Elgato Control Center.app"), "Lights", "x"), ic["light"])
    apps.write("Apps")

    ops = PageWriter(pages / PAGE_OPS.upper())
    ops.add(0, 0, action_back("x"), ic["back"])
    ops.add(1, 0, action_open(cmd("chezmoi-apply.command"), "Apply", "x"), ic["apply"])
    ops.add(2, 0, action_open(cmd("chezmoi-diff.command"), "Diff", "x"), ic["diff"])
    ops.add(3, 0, action_open(cmd("check-secrets.command"), "Secrets", "x"), ic["secrets"])
    ops.add(4, 0, action_open(cmd("ansible-brew.command"), "Ansible", "x"), ic["brew"])
    ops.add(0, 1, action_open(cmd("pass-login.command"), "Pass login", "x"), ic["pass"])
    ops.add(1, 1, action_open(cmd("ensure-ssh-agent.command"), "SSH agent", "x"), ic["ssh"])
    ops.add(2, 1, action_open(cmd("open-dotfiles.command"), "Repo", "x"), ic["repo"])
    ops.add(3, 1, action_open(cmd("himalaya.command"), "Himalaya", "x"), ic["himalaya"])
    ops.add(4, 1, action_open(cmd("topgrade.command"), "Topgrade", "x"), ic["topg"])
    ops.add(0, 2, action_open(cmd("mount-nas.command"), "NAS", "x"), ic["nas"])
    ops.add(1, 2, action_open(cmd("chezmoi-status.command"), "Status", "x"), ic["status"])
    ops.add(2, 2, action_open(cmd("aerospace-reload.command"), "Aero", "x"), ic["aero"])
    ops.add(3, 2, action_website("https://github.com/axelquack/dotfiles-macos", "GitHub", "x"), ic["gh"])
    ops.add(4, 2, action_open(cmd("grok-tui.command"), "Grok", "x"), ic["grok"])
    ops.write("Ops")

    studio = PageWriter(pages / PAGE_STUDIO.upper())
    studio.add(0, 0, action_back("x"), ic["back"])
    studio.add(1, 0, action_open(app("Elgato Camera Hub.app"), "Camera Hub", "x"), ic["cam"])
    studio.add(2, 0, action_open(app("Elgato Control Center.app"), "Lights", "x"), ic["light"])
    studio.add(3, 0, action_open(app("Screenshot.app"), "Screenshot", "x"), ic["shot"])
    studio.add(4, 0, action_open(app("Screenshot.app"), "Record", "x"), ic["rec"])
    studio.add(0, 1, action_media(4, "Mute", "x"), ic["mute"])
    studio.add(1, 1, action_media(1, "Play", "x"), ic["play"])
    studio.add(2, 1, action_media(5, "Vol -", "x"), ic["vol-"])
    studio.add(3, 1, action_media(6, "Vol +", "x"), ic["vol+"])
    studio.add(4, 1, action_open(app("Roon.app"), "Roon", "x"), ic["roon"])
    studio.add(0, 2, action_open(hue_app("Tokio"), "Tokio", "x"), ic["hue-tokio"])
    studio.add(1, 2, action_open(hue_app("Lesen"), "Lesen", "x"), ic["hue-lesen"])
    studio.add(2, 2, action_open(hue_app("Malibu pink"), "Pink", "x"), ic["hue-pink"])
    studio.add(3, 2, action_open(hue_app("Gedimmt"), "Dim", "x"), ic["hue-nacht"])
    studio.add(4, 2, action_open(hue_app("--off"), "Aus", "x"), ic["hue-off"])
    studio.write("Studio")

    gitp = PageWriter(pages / PAGE_GIT.upper())
    gitp.add(0, 0, action_back("x"), ic["back"])
    gitp.add(1, 0, action_open(cmd("git-status.command"), "Status", "x"), ic["git-status"])
    gitp.add(2, 0, action_open(cmd("git-pull.command"), "Pull", "x"), ic["pull"])
    gitp.add(3, 0, action_open(cmd("git-push.command"), "Push", "x"), ic["push"])
    gitp.add(4, 0, action_open(cmd("git-log.command"), "Log", "x"), ic["log"])
    gitp.add(0, 1, action_open(cmd("git-diff.command"), "Diff", "x"), ic["git-diff"])
    gitp.add(1, 1, action_open(cmd("check-secrets.command"), "Secrets", "x"), ic["secrets"])
    gitp.add(2, 1, action_open(cmd("open-dotfiles.command"), "Repo", "x"), ic["repo"])
    gitp.write("Git")


def write_mcp_pages(profile_root: Path) -> None:
    """MCP Deck is a virtual Stream Deck XL (8×4), not MK.2 5×3."""
    pages = profile_root / "Profiles"
    if pages.exists():
        shutil.rmtree(pages)
    pages.mkdir(parents=True)
    ic = icon_catalog()
    mcp = PageWriter(pages / PAGE_MCP.upper())
    # Row 0 — dotfiles ops
    mcp.add(0, 0, action_open(cmd("chezmoi-apply.command"), "Apply", "x"), ic["apply"])
    mcp.add(1, 0, action_open(cmd("chezmoi-diff.command"), "Diff", "x"), ic["diff"])
    mcp.add(2, 0, action_open(cmd("check-secrets.command"), "Secrets", "x"), ic["secrets"])
    mcp.add(3, 0, action_open(cmd("ansible-brew.command"), "Ansible", "x"), ic["brew"])
    mcp.add(4, 0, action_open(cmd("topgrade.command"), "Topgrade", "x"), ic["topg"])
    mcp.add(5, 0, action_open(cmd("chezmoi-status.command"), "Status", "x"), ic["status"])
    mcp.add(6, 0, action_open(cmd("aerospace-reload.command"), "Aero", "x"), ic["aero"])
    mcp.add(7, 0, action_open(cmd("mount-nas.command"), "NAS", "x"), ic["nas"])
    # Row 1 — secrets, git, grok
    mcp.add(0, 1, action_open(cmd("pass-login.command"), "Pass login", "x"), ic["pass"])
    mcp.add(1, 1, action_open(cmd("ensure-ssh-agent.command"), "SSH agent", "x"), ic["ssh"])
    mcp.add(2, 1, action_open(cmd("open-dotfiles.command"), "Repo", "x"), ic["repo"])
    mcp.add(3, 1, action_open(cmd("himalaya.command"), "Himalaya", "x"), ic["himalaya"])
    mcp.add(4, 1, action_open(cmd("grok-tui.command"), "Grok", "x"), ic["grok"])
    mcp.add(5, 1, action_open(cmd("git-pull.command"), "Pull", "x"), ic["pull"])
    mcp.add(6, 1, action_open(cmd("git-push.command"), "Push", "x"), ic["push"])
    mcp.add(7, 1, action_open(cmd("git-log.command"), "Log", "x"), ic["log"])
    # Row 2 — AeroSpace workspaces (CLI applets; no Accessibility hotkeys)
    mcp.add(0, 2, action_open(workspace_app("web"), "web", "x"), ic["web"])
    mcp.add(1, 2, action_open(workspace_app("code"), "code", "x"), ic["code"])
    mcp.add(2, 2, action_open(workspace_app("term"), "term", "x"), ic["term"])
    mcp.add(3, 2, action_open(workspace_app("comms"), "comms", "x"), ic["comms"])
    mcp.add(4, 2, action_open(workspace_app("docs"), "docs", "x"), ic["docs"])
    mcp.add(5, 2, action_open(workspace_app("media"), "media", "x"), ic["media"])
    mcp.add(6, 2, action_open(workspace_app("files"), "files", "x"), ic["files"])
    mcp.add(7, 2, action_open(workspace_app("games"), "games", "x"), ic["games"])
    # Row 3 — daily apps + remaining workspaces
    mcp.add(0, 3, action_open(app("Cursor.app"), "Cursor", "x"), ic["cursor"])
    mcp.add(1, 3, action_open(app("Zed.app"), "Zed", "x"), ic["zed"])
    mcp.add(2, 3, action_open(app("Obsidian.app"), "Obsidian", "x"), ic["obsidian"])
    mcp.add(3, 3, action_open(app("Brave Browser.app"), "Brave", "x"), ic["brave"])
    mcp.add(4, 3, action_open(workspace_app("design"), "design", "x"), ic["design"])
    mcp.add(5, 3, action_open(workspace_app("vm"), "vm", "x"), ic["vm"])
    mcp.add(6, 3, action_open(app("Elgato Camera Hub.app"), "Cam Hub", "x"), ic["cam"])
    mcp.add(7, 3, action_open(app("Elgato Control Center.app"), "Lights", "x"), ic["light"])
    mcp.write("MCP Actions")


def find_profile(model: str, uuid_substr: str | None = None) -> Path | None:
    if not PROFILES_V3.is_dir():
        return None
    for child in PROFILES_V3.glob("*.sdProfile"):
        man = child / "manifest.json"
        if not man.is_file():
            continue
        try:
            data = json.loads(man.read_text())
        except json.JSONDecodeError:
            continue
        device = data.get("Device") or {}
        if device.get("Model") == model:
            return child
        if uuid_substr and uuid_substr in str(device.get("UUID", "")):
            return child
    return None


def write_profile_manifest(profile_root: Path, name: str, model: str, device_uuid: str, current: str, pages: list[str]) -> None:
    manifest = {
        "Device": {"Model": model, "UUID": device_uuid},
        "Name": name,
        "Pages": {
            "Current": current.lower(),
            "Default": current.lower(),
            "Pages": [p.lower() for p in pages],
        },
        "Version": "3.0",
    }
    profile_root.mkdir(parents=True, exist_ok=True)
    (profile_root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print target paths only")
    args = parser.parse_args()

    if not BIN.is_dir():
        print(f"ERROR: missing {BIN} — run chezmoi apply first", file=sys.stderr)
        return 1

    hw = find_profile(HW_MODEL, "4057/109")
    mcp = find_profile(MCP_MODEL)

    if args.dry_run:
        print(f"hardware profile: {hw}")
        print(f"MCP profile:      {mcp}")
        print(f"action scripts:   {BIN}")
        return 0

    if hw is None:
        hw = PROFILES_V3 / (str(uuid.uuid4()).upper() + ".sdProfile")
        print(f"creating hardware profile {hw.name}")
        device_uuid = "@(1)[4057/109]"
    else:
        existing = json.loads((hw / "manifest.json").read_text())
        device_uuid = (existing.get("Device") or {}).get("UUID") or "@(1)[4057/109]"
        print(f"updating hardware profile {hw.name}")

    write_hardware_pages(hw)
    write_profile_manifest(
        hw,
        name="dotfiles",
        model=HW_MODEL,
        device_uuid=device_uuid,
        current=PAGE_HOME,
        pages=[PAGE_HOME, PAGE_TWO],
    )

    if mcp is None:
        print("WARN: MCP Deck profile not found (enable MCP Deck in Stream Deck Preferences)", file=sys.stderr)
    else:
        existing = json.loads((mcp / "manifest.json").read_text())
        mcp_uuid = (existing.get("Device") or {}).get("UUID") or ""
        print(f"updating MCP profile {mcp.name}")
        write_mcp_pages(mcp)
        write_profile_manifest(
            mcp,
            name="MCP Actions",
            model=MCP_MODEL,
            device_uuid=mcp_uuid,
            current=PAGE_MCP,
            pages=[PAGE_MCP],
        )

    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
