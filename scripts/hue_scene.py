#!/usr/bin/env python3
"""Recall a Philips Hue scene (or turn the room off).

Public repo: no bridge IPs or usernames here.

Auth (never printed):
  1. ~/.config/streamdeck/hue.local  — written by --bootstrap
  2. scripts/hue.local               — optional gitignored overrides
  3. We Love Lights whitelist        — --bootstrap only (Stream Deck
     applets cannot read that Group Container)

Default room: Keller (Fitness Schreibtisch).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_ROOM = "Keller (Fitness Schreibtisch)"
CONFIG_DIR = Path.home() / ".config/streamdeck"
BOOTSTRAP_FILE = CONFIG_DIR / "hue.local"
WLL_PLIST = (
    Path.home()
    / "Library/Group Containers/PF8C99TXS7.group.com.windhahn.welovelights"
    / "Library/Preferences/PF8C99TXS7.group.com.windhahn.welovelights.plist"
)
ALIASES = {
    "lesen": "Lesen",
    "read": "Lesen",
    "tokio": "Tokio",
    "tokyo": "Tokio",
    "malibu": "Malibu pink",
    "pink": "Malibu pink",
    "malibu pink": "Malibu pink",
    "malibu-pink": "Malibu pink",
    "dim": "Gedimmt",
    "gedimmt": "Gedimmt",
    "nacht": "Gedimmt",
    "night": "Gedimmt",
    "nachtlicht": "Gedimmt",
}


def _script_dir() -> Path:
    return Path(__file__).resolve().parent


def _parse_kv(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        out[key.strip().lower()] = val.strip().strip('"').strip("'")
    return out


def load_local() -> dict[str, str]:
    # Bootstrap first, then repo overlay (room= without clobbering token).
    out = _parse_kv(BOOTSTRAP_FILE)
    overlay = _parse_kv(_script_dir() / "hue.local")
    out.update(overlay)
    return out


def load_wll_connections() -> list[dict]:
    if not WLL_PLIST.is_file():
        return []
    try:
        import plistlib
    except ImportError:
        return []
    try:
        data = plistlib.loads(WLL_PLIST.read_bytes())
    except OSError:
        return []
    raw = data.get("connectionsWhitelisted") or []
    conns = []
    for item in raw:
        if isinstance(item, str):
            try:
                item = json.loads(item)
            except json.JSONDecodeError:
                continue
        if isinstance(item, dict) and item.get("token"):
            conns.append(item)
    return conns


def http_json(method: str, url: str, body: dict | None = None, timeout: float = 4.0):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"hue: HTTP {exc.code}") from None
    except urllib.error.URLError:
        raise RuntimeError("hue: bridge unreachable") from None


def connections(local: dict[str, str], *, allow_wll: bool) -> list[tuple[str, str]]:
    """Return (base_url, token) pairs. Never print these."""
    out: list[tuple[str, str]] = []
    host = (local.get("host") or "").rstrip("/")
    token = local.get("token") or ""
    if host and token:
        if not host.startswith("http"):
            host = "http://" + host
        out.append((host, token))
    if allow_wll:
        for conn in load_wll_connections():
            h = (conn.get("localHost") or conn.get("host") or "").rstrip("/")
            t = conn.get("token") or ""
            if h and t:
                if not h.startswith("http"):
                    h = "http://" + h
                pair = (h, t)
                if pair not in out:
                    out.append(pair)
    if not out:
        raise RuntimeError(
            "hue: no bridge login. Run: python3 scripts/hue_scene.py --bootstrap"
        )
    return out


def find_room(conns: list[tuple[str, str]], room_name: str):
    want = room_name.casefold()
    for base, token in conns:
        groups = http_json("GET", f"{base}/api/{token}/groups")
        if not isinstance(groups, dict):
            continue
        for gid, group in groups.items():
            if not isinstance(group, dict):
                continue
            if (group.get("name") or "").casefold() != want:
                continue
            if group.get("type") not in ("Room", "Zone", "Entertainment"):
                continue
            return base, token, str(gid), group
    raise RuntimeError(f"hue: room not found: {room_name}")


def scenes_for_group(base: str, token: str, gid: str) -> list[tuple[str, str]]:
    scenes = http_json("GET", f"{base}/api/{token}/scenes")
    if not isinstance(scenes, dict):
        return []
    found: list[tuple[str, str]] = []
    for sid, scene in scenes.items():
        if not isinstance(scene, dict):
            continue
        if str(scene.get("group") or "") != str(gid):
            continue
        if scene.get("recycle"):
            continue
        name = scene.get("name") or sid
        found.append((name, sid))
    return found


def resolve_scene_name(raw: str) -> str:
    key = " ".join(raw.strip().casefold().split())
    return ALIASES.get(key, raw.strip())


def write_bootstrap(host: str, token: str, room: str) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    body = (
        "# Generated by hue_scene.py --bootstrap. Do not commit.\n"
        f"room={room}\n"
        f"host={host}\n"
        f"token={token}\n"
    )
    BOOTSTRAP_FILE.write_text(body)
    os.chmod(BOOTSTRAP_FILE, 0o600)


def bootstrap(room: str) -> int:
    local = load_local()
    conns = connections(local, allow_wll=True)
    base, token, _gid, group = find_room(conns, room)
    write_bootstrap(base, token, group.get("name") or room)
    print(f"hue: saved login for {group.get('name')}")
    return 0


def run(args: argparse.Namespace) -> int:
    local = load_local()
    room = args.room or local.get("room") or DEFAULT_ROOM
    if args.bootstrap:
        return bootstrap(room)

    conns = connections(local, allow_wll=False)
    base, token, gid, group = find_room(conns, room)

    if args.list:
        print(f"{group.get('name')} ({len(group.get('lights') or [])} lights)")
        for name, _sid in scenes_for_group(base, token, gid):
            print(f"  {name}")
        return 0

    turn_off = args.off or (args.scene or "").strip().casefold() in {"off", "aus"}
    if turn_off:
        http_json("PUT", f"{base}/api/{token}/groups/{gid}/action", {"on": False})
        return 0

    if not args.scene:
        raise RuntimeError("hue: scene name required (or --off / --list)")

    want = resolve_scene_name(args.scene).casefold()
    matches = [(n, s) for n, s in scenes_for_group(base, token, gid) if n.casefold() == want]
    if not matches:
        raise RuntimeError(f"hue: scene not in {room}: {args.scene}")
    http_json("PUT", f"{base}/api/{token}/groups/{gid}/action", {"scene": matches[0][1]})
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scene", nargs="?", help="Hue scene name (or off/aus)")
    parser.add_argument("--off", action="store_true", help="Turn the room off")
    parser.add_argument("--list", action="store_true", help="List scenes for the room")
    parser.add_argument("--room", help="Hue room name")
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Copy We Love Lights login into ~/.config/streamdeck/hue.local",
    )
    args = parser.parse_args()
    try:
        return run(args)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
