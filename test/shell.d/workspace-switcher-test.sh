#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'shell/plugins/workspace-switcher/manifest.json'), 'utf8'))
const qmlContent = fs.readFileSync(path.join(root, 'shell/plugins/workspace-switcher/WorkspaceSwitcher.qml'), 'utf8')
const tilingLua = fs.readFileSync(path.join(root, 'default/hypr/bindings/tiling.lua'), 'utf8')

assertEqual(manifest.id, 'omarchy.workspace-switcher', 'manifest declares omarchy.workspace-switcher')
assert(manifest.kinds.includes('overlay'), 'manifest declares overlay kind')
assertEqual(manifest.entryPoints.overlay, 'WorkspaceSwitcher.qml', 'overlay points to WorkspaceSwitcher.qml')

// QML lifecycle API assertions
assert(qmlContent.includes('function open(payloadJson)'), 'WorkspaceSwitcher exposes open lifecycle')
assert(qmlContent.includes('function close()'), 'WorkspaceSwitcher exposes close lifecycle')
assert(qmlContent.includes('function dismiss()'), 'WorkspaceSwitcher exposes dismiss lifecycle')
assert(qmlContent.includes('function toggle()'), 'WorkspaceSwitcher exposes toggle lifecycle')
assert(qmlContent.includes('function reloadWorkspaces()'), 'WorkspaceSwitcher exposes reloadWorkspaces')
assert(qmlContent.includes('function activateWorkspace(id)'), 'WorkspaceSwitcher exposes activateWorkspace')
assert(qmlContent.includes('import Quickshell.Hyprland'), 'WorkspaceSwitcher imports Quickshell.Hyprland')

// Hyprland keybindings assertions
assert(tilingLua.includes('omarchy.workspace-switcher'), 'tiling.lua binds workspace-switcher overlay')
assert(tilingLua.includes('ALT + TAB'), 'tiling.lua binds ALT+TAB to workspace switcher')
assert(tilingLua.includes('ALT + SPACE') || tilingLua.includes('SUPER + TAB'), 'tiling.lua binds ALT+SPACE or SUPER+TAB')
JS
