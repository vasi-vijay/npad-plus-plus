#!/usr/bin/env python3
"""Regenerates catalog.json from every <plugin>/manifest.json + main.js in this folder.

Run it after changing any plugin script: the app refuses to install a script whose SHA-256 differs from the catalog.
Usage: ./build_catalog.py [raw-base-url]
"""
import hashlib, json, pathlib, sys

BASE = (sys.argv[1] if len(sys.argv) > 1 else
        "https://raw.githubusercontent.com/vasi-vijay/npad-plus-plus/main/macos-app/plugins").rstrip("/")
root = pathlib.Path(__file__).resolve().parent
entries = []
for manifest_path in sorted(root.glob("*/manifest.json")):
    manifest = json.loads(manifest_path.read_text())
    script = manifest_path.parent / "main.js"
    manifest["downloadURL"] = f"{BASE}/{manifest_path.parent.name}/main.js"
    manifest["sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    entries.append(manifest)
(root / "catalog.json").write_text(json.dumps({"plugins": entries}, indent=2) + "\n")
print(f"Wrote catalog.json with {len(entries)} plugins")
