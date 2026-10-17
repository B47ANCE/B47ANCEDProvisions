#!/usr/bin/env python3
"""Recheck read-only fruit-drying evidence; never imports or executes game code."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def safe_path(root, name):
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or ":" in name or "\\" in name:
        raise ValueError("Unsafe evidence path")
    result = (root / name).resolve()
    if not result.is_relative_to(root.resolve()):
        raise ValueError("Evidence escapes its root")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-root", type=Path, required=True)
    parser.add_argument("--steam-build", required=True)
    args = parser.parse_args()
    report = json.loads((ROOT / "docs/FRUIT_DRYING_EVIDENCE.json").read_text(encoding="utf-8"))
    if args.steam_build != report["steam_build"]:
        raise ValueError("STALE_BUILD: repeat the audit for this installed Steam build")
    count = 0
    for evidence in report["source_files"]:
        root = ROOT if evidence["scope"] == "project" else args.game_root
        data = safe_path(root, evidence["path"]).read_bytes()
        if hashlib.sha256(data).hexdigest() != evidence["sha256"]:
            raise ValueError("STALE_SOURCE: " + evidence["id"] + " " + evidence["path"])
        length = len(data.decode("utf-8-sig").splitlines())
        if not all(1 <= first <= last <= length for first, last in evidence["lines"]):
            raise ValueError("Invalid line range: " + evidence["id"])
        count += 1
    for evidence in report["native_classes"]:
        with zipfile.ZipFile(safe_path(args.game_root, evidence["path"])) as archive:
            data = archive.read(evidence["member"])
        if hashlib.sha256(data).hexdigest() != evidence["sha256"]:
            raise ValueError("STALE_SOURCE: " + evidence["id"] + " " + evidence["member"])
        count += 1
    print(f"PASS {count} source/class fingerprints and source line ranges")
    print("SOURCE_HASH_MATCH only; online references not fingerprinted; native metadata does not prove Lua authority.")
    print("SP/dedicated NOT TESTED; G7 and stable G8 remain BLOCKED.")


if __name__ == "__main__":
    main()
