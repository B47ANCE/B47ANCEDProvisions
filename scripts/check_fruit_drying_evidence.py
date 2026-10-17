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
    parser.add_argument("--preview", action="store_true", help="Recheck the current read-only prototype evidence")
    args = parser.parse_args()
    name = "FRUIT_DRYING_PREVIEW_EVIDENCE.json" if args.preview else "FRUIT_DRYING_EVIDENCE.json"
    report = json.loads((ROOT / "docs" / name).read_text(encoding="utf-8"))
    if args.steam_build != report["steam_build"]:
        raise ValueError("STALE_BUILD: repeat the audit for this installed Steam build")
    count = 0
    for evidence in report["source_files"]:
        root = ROOT if evidence.get("scope") == "project" else args.game_root
        data = safe_path(root, evidence["path"]).read_bytes()
        if hashlib.sha256(data).hexdigest() != evidence["sha256"]:
            raise ValueError("STALE_SOURCE: " + evidence.get("id", "source") + " " + evidence["path"])
        length = len(data.decode("utf-8-sig").splitlines())
        ranges = evidence["lines"]
        if ranges and isinstance(ranges[0], int):
            ranges = [ranges]
        if not all(1 <= first <= last <= length for first, last in ranges):
            raise ValueError("Invalid line range: " + evidence.get("id", evidence["path"]))
        count += 1
    for evidence in report["native_classes"]:
        with zipfile.ZipFile(safe_path(args.game_root, evidence["path"])) as archive:
            data = archive.read(evidence["member"])
        if hashlib.sha256(data).hexdigest() != evidence["sha256"]:
            raise ValueError("STALE_SOURCE: " + evidence.get("id", "native") + " " + evidence["member"])
        count += 1
    if "prototype_source" in report:
        source = report["prototype_source"]
        data = safe_path(ROOT, source["path"]).read_bytes()
        if hashlib.sha256(data).hexdigest() != source["sha256"]:
            # Git may check this project-owned Lua text out as CRLF on Windows.
            # Preserve the recorded LF fingerprint; game/native evidence stays exact.
            if hashlib.sha256(data.replace(b"\r\n", b"\n")).hexdigest() != source["sha256"]:
                raise ValueError("STALE_SOURCE: prototype module")
            print("NOTE: prototype matches recorded LF text after CRLF normalization")
        count += 1
    print(f"PASS {count} source/class fingerprints and source line ranges")
    print("SOURCE_HASH_MATCH only; online references not fingerprinted; native metadata does not prove Lua authority.")
    print("SP/dedicated NOT TESTED; G7 and stable G8 remain BLOCKED.")


if __name__ == "__main__":
    main()
