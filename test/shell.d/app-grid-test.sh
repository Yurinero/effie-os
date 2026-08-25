#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const categories = requireFromRoot('shell/plugins/app-grid/AppCategories.js')
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'shell/plugins/app-grid/manifest.json'), 'utf8'))
const appGridQml = fs.readFileSync(path.join(root, 'shell/plugins/app-grid/AppGrid.qml'), 'utf8')
const barWidgetQml = fs.readFileSync(path.join(root, 'shell/plugins/app-grid/BarWidget.qml'), 'utf8')

assertEqual(manifest.id, 'omarchy.app-grid', 'manifest declares omarchy.app-grid')
assert(manifest.kinds.includes('overlay'), 'manifest declares overlay kind')
assert(manifest.kinds.includes('bar-widget'), 'manifest declares bar-widget kind')

const sampleEntries = [
  { name: 'Chromium', categories: 'Network;WebBrowser;', id: 'chromium.desktop' },
  { name: 'Neovim', categories: 'Development;TextEditor;', id: 'nvim.desktop' },
  { name: 'MPV', categories: 'AudioVideo;Player;', id: 'mpv.desktop' },
  { name: 'Obsidian', categories: 'Office;', id: 'obsidian.desktop' },
  { name: 'Superfile', categories: 'System;FileManager;Utility;', id: 'Superfile.desktop' },
  { name: 'Steam', categories: 'Game;', id: 'steam.desktop' }
]

assertEqual(categories.getCategoryForEntry(sampleEntries[0]), 'internet', 'Chromium maps to internet')
assertEqual(categories.getCategoryForEntry(sampleEntries[1]), 'development', 'Neovim maps to development')
assertEqual(categories.getCategoryForEntry(sampleEntries[2]), 'media', 'MPV maps to media')
assertEqual(categories.getCategoryForEntry(sampleEntries[3]), 'productivity', 'Obsidian maps to productivity')
assertEqual(categories.getCategoryForEntry(sampleEntries[4]), 'utilities', 'Superfile maps to utilities')
assertEqual(categories.getCategoryForEntry(sampleEntries[5]), 'games', 'Steam maps to games')

// Category filter
const internetApps = categories.filterEntries(sampleEntries, 'internet', '')
assertEqual(internetApps.length, 1, 'category filter returns only matching category')
assertEqual(internetApps[0].name, 'Chromium', 'category filter matches Chromium')

// Search filter across categories
const searchDev = categories.filterEntries(sampleEntries, 'all', 'nvim')
assertEqual(searchDev.length, 1, 'search filter finds nvim')
assertEqual(searchDev[0].name, 'Neovim', 'search filter finds Neovim')

// Alphabetical sort
const allSorted = categories.filterEntries(sampleEntries, 'all', '')
assertEqual(allSorted[0].name, 'Chromium', 'first alphabetically is Chromium')
assertEqual(allSorted[allSorted.length - 1].name, 'Superfile', 'last alphabetically is Superfile')

// QML integration checks
assert(appGridQml.includes('function open(payloadJson)'), 'AppGrid exposes open lifecycle')
assert(appGridQml.includes('function close()'), 'AppGrid exposes close lifecycle')
assert(appGridQml.includes('function dismiss()'), 'AppGrid exposes dismiss lifecycle')
assert(appGridQml.includes('function toggle()'), 'AppGrid exposes toggle lifecycle')
assert(appGridQml.includes('root.shell.appLibrary.launch('), 'AppGrid delegates launch to AppLibrary')
assert(barWidgetQml.includes('omarchy.app-grid'), 'BarWidget targets omarchy.app-grid')
JS
