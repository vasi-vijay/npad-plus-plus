#!/usr/bin/env bash
# Builds tests/plugin-runner from the app's own PluginStore.swift (JSPluginRunner).
set -e
cd "$(dirname "$0")"
mkdir -p build
cp runner_main.swift build/main.swift
swiftc -O ../../Sources/NotepadPlusMac/Models/PluginStore.swift build/main.swift -o build/plugin-runner
echo "Built tests/build/plugin-runner"
