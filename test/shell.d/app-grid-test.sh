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

// Test wrapped and unwrapped entry representations
const sampleRows = [
  { entry: { name: 'Chromium', categories: 'Network;WebBrowser;', id: 'chromium.desktop', icon: 'chromium' } },
  { entry: { name: 'Neovim', categories: 'Development;TextEditor;', id: 'nvim.desktop', icon: 'nvim' } },
  { entry: { name: 'OBS Studio', categories: 'AudioVideo;Recorder;', id: 'com.obsproject.Studio.desktop', icon: 'com.obsproject.Studio' } },
  { entry: { name: 'Obsidian', categories: 'Office;', id: 'obsidian.desktop', icon: 'obsidian' } },
  { entry: { name: 'Superfile', categories: 'System;FileManager;Utility;', id: 'Superfile.desktop', icon: 'superfile' } },
  { entry: { name: 'Steam', categories: 'Game;', id: 'steam.desktop', icon: 'steam' } },
  { entry: { name: 'X', id: 'X', exec: 'omarchy-launch-webapp https://x.com/', icon: 'x' } },
  { entry: { name: 'YouTube', id: 'YouTube', exec: 'omarchy-launch-webapp https://youtube.com/', icon: 'youtube' } },
  { entry: { name: 'cliamp', categories: 'AudioVideo;Audio;Player;', id: 'cliamp.desktop', icon: 'cliamp' } },
  { entry: { name: 'Basecamp', id: 'Basecamp', exec: 'omarchy-launch-webapp https://launchpad.37signals.com', icon: 'basecamp' } },
  { entry: { name: 'Discord', id: 'Discord', exec: 'omarchy-launch-webapp https://discord.com/', icon: 'discord' } }
]

assertEqual(categories.getCategoryForEntry(sampleRows[0]), 'internet', 'Chromium maps to internet')
assertEqual(categories.getCategoryForEntry(sampleRows[1]), 'development', 'Neovim maps to development')
assertEqual(categories.getCategoryForEntry(sampleRows[2]), 'media', 'OBS Studio maps to media')
assertEqual(categories.getCategoryForEntry(sampleRows[3]), 'productivity', 'Obsidian maps to productivity')
assertEqual(categories.getCategoryForEntry(sampleRows[4]), 'utilities', 'Superfile maps to utilities')
assertEqual(categories.getCategoryForEntry(sampleRows[5]), 'games', 'Steam maps to games')
assertEqual(categories.getCategoryForEntry(sampleRows[6]), 'internet', 'X maps to internet')
assertEqual(categories.getCategoryForEntry(sampleRows[7]), 'media', 'YouTube maps to media')
assertEqual(categories.getCategoryForEntry(sampleRows[8]), 'media', 'cliamp maps to media')
assertEqual(categories.getCategoryForEntry(sampleRows[9]), 'productivity', 'Basecamp maps to productivity')
assertEqual(categories.getCategoryForEntry(sampleRows[10]), 'internet', 'Discord maps to internet')

// Category filter
const internetApps = categories.filterEntries(sampleRows, 'internet', '')
assertEqual(internetApps.length, 3, 'internet filter returns 3 apps (Chromium, Discord, X)')
assertEqual(internetApps[0].name, 'Chromium', 'first internet app is Chromium')
assertEqual(internetApps[1].name, 'Discord', 'second internet app is Discord')
assertEqual(internetApps[2].name, 'X', 'third internet app is X')

// Search filter across categories
const searchObs = categories.filterEntries(sampleRows, 'all', 'obs')
assertEqual(searchObs.length, 2, 'search finds OBS Studio and Obsidian')

// Alphabetical sort
const allSorted = categories.filterEntries(sampleRows, 'all', '')
assertEqual(allSorted[0].name, 'Basecamp', 'first alphabetically is Basecamp')
assertEqual(allSorted[allSorted.length - 1].name, 'YouTube', 'last alphabetically is YouTube')

// QML integration checks
assert(appGridQml.includes('function open(payloadJson)'), 'AppGrid exposes open lifecycle')
assert(appGridQml.includes('function close()'), 'AppGrid exposes close lifecycle')
assert(appGridQml.includes('function dismiss()'), 'AppGrid exposes dismiss lifecycle')
assert(appGridQml.includes('function toggle()'), 'AppGrid exposes toggle lifecycle')
assert(appGridQml.includes('root.shell.appLibrary.launch('), 'AppGrid delegates launch to AppLibrary')
assert(barWidgetQml.includes('omarchy.app-grid'), 'BarWidget targets omarchy.app-grid')
JS
