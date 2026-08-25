var CATEGORIES = [
  { id: "all", label: "All", icon: "󰀻" },
  { id: "internet", label: "Internet", icon: "󰖟" },
  { id: "development", label: "Development", icon: "󰅩" },
  { id: "media", label: "Media & Design", icon: "󰕼" },
  { id: "productivity", label: "Productivity", icon: "󰏫" },
  { id: "utilities", label: "Utilities & System", icon: "󰘳" },
  { id: "games", label: "Games", icon: "󰊗" }
]

var CATEGORY_MAP = {
  media: [
    "audiovideo", "audio", "video", "graphics", "photography",
    "rastergraphics", "vectorgraphics", "player", "recorder", "music",
    "midi", "2dgraphics", "3dgraphics", "art", "scanning", "audiovideoediting"
  ],
  internet: [
    "network", "webbrowser", "email", "chat", "instantmessaging",
    "feed", "filetransfer", "p2p", "remoteaccess", "telephony", "ircclient", "news"
  ],
  development: [
    "development", "ide", "texteditor", "debugger", "revisioncontrol",
    "translation", "guidesigner", "webdevelopment", "building"
  ],
  productivity: [
    "office", "wordprocessor", "spreadsheet", "presentation",
    "publishing", "finance", "calendar", "contactmanagement", "viewer", "dictionary", "projectmanagement"
  ],
  games: [
    "game", "actiongame", "adventuregame", "arcadegame", "boardgame",
    "cardgame", "emulator", "logicgame", "roleplaying", "shooter",
    "simulation", "sportsgame", "strategygame"
  ],
  utilities: [
    "system", "utility", "settings", "packagemanager", "monitor",
    "security", "archiving", "compression", "filetools", "accessibility",
    "core", "hardwaresettings", "filemanager", "filesystem", "calculator", "terminalemulator", "maps"
  ]
}

function unwrapEntry(row) {
  if (!row) return null
  return (row && row.entry) ? row.entry : row
}

function normalizeCategories(rawCategories) {
  if (!rawCategories) return []
  if (Array.isArray(rawCategories)) {
    return rawCategories.map(function(c) { return String(c || "").trim().toLowerCase() })
  }
  if (typeof rawCategories === "string") {
    return rawCategories.split(";").map(function(c) { return c.trim().toLowerCase() }).filter(function(c) { return c.length > 0 })
  }
  return []
}

function getCategoryForEntry(raw) {
  var entry = unwrapEntry(raw)
  if (!entry) return "utilities"

  var name = String((entry && entry.name) || "").toLowerCase().trim()
  var id = String((entry && entry.id) || "").toLowerCase().trim()
  var comment = String((entry && entry.comment) || "").toLowerCase()
  var exec = String((entry && entry.exec) || "").toLowerCase()
  var fullText = [name, id, comment, exec].join(" ")

  // 1. Direct Name / ID / Exec URL recognition
  if (name === "x" || id === "x" || id === "x.desktop" || /x\.com|twitter/i.test(fullText)) {
    return "internet"
  }
  if (name === "youtube" || id === "youtube" || id === "youtube.desktop" || /youtube\.com/i.test(fullText)) {
    return "media"
  }

  // 2. High-priority keyword heuristics
  if (/\b(obs|studio|mpv|spotify|cliamp|pinta|gimp|kdenlive|inkscape|blender|audacity|vlc|aether|youtube|photos?|audio|music|video|player|camera)\b/i.test(fullText)) {
    return "media"
  }
  if (/\b(obsidian|office|writer|calc|document|basecamp|notion|notes?|pdf|contacts?|calendar|tasks?)\b/i.test(fullText)) {
    return "productivity"
  }
  if (/\b(chromium|firefox|brave|chrome|browser|discord|telegram|slack|whatsapp|signal|hey|zoom|mail|chat|messages?|twitter)\b/i.test(fullText)) {
    return "internet"
  }
  if (/\b(neovim|nvim|vscode|code|studio code|sublime|git|lazygit|debugger|compiler|opencode)\b/i.test(fullText)) {
    return "development"
  }
  if (/\b(game|steam|retro|play|heroic|lutris|battlenet|minecraft)\b/i.test(fullText)) {
    return "games"
  }

  // 3. XDG standard category mapping
  var cats = normalizeCategories(entry.categories)
  for (var categoryKey in CATEGORY_MAP) {
    var keywords = CATEGORY_MAP[categoryKey]
    for (var i = 0; i < cats.length; i++) {
      if (keywords.indexOf(cats[i]) !== -1) return categoryKey
    }
  }

  return "utilities"
}

function filterEntries(entries, categoryId, searchQuery) {
  var list = entries || []
  var query = String(searchQuery || "").trim().toLowerCase()
  var selectedCategory = String(categoryId || "all")

  var filtered = []
  for (var i = 0; i < list.length; i++) {
    var entry = unwrapEntry(list[i])
    if (!entry) continue

    // Category check
    if (selectedCategory !== "all") {
      var cat = getCategoryForEntry(entry)
      if (cat !== selectedCategory) continue
    }

    // Search query check
    if (query.length > 0) {
      var name = String(entry.name || "").toLowerCase()
      var genericName = String(entry.genericName || "").toLowerCase()
      var comment = String(entry.comment || "").toLowerCase()
      var id = String(entry.id || "").toLowerCase()
      if (name.indexOf(query) === -1 &&
          genericName.indexOf(query) === -1 &&
          comment.indexOf(query) === -1 &&
          id.indexOf(query) === -1) {
        continue
      }
    }

    filtered.push(entry)
  }

  // Sort alphabetically by name
  filtered.sort(function(a, b) {
    var nameA = String((a && a.name) || (a && a.id) || "").toLowerCase()
    var nameB = String((b && b.name) || (b && b.id) || "").toLowerCase()
    return nameA.localeCompare(nameB)
  })

  return filtered
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    CATEGORIES: CATEGORIES,
    CATEGORY_MAP: CATEGORY_MAP,
    unwrapEntry: unwrapEntry,
    getCategoryForEntry: getCategoryForEntry,
    filterEntries: filterEntries
  }
}
