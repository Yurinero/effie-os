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
  internet: [
    "network", "webbrowser", "email", "chat", "instantmessaging",
    "feed", "filetransfer", "p2p", "remoteaccess", "telephony", "ircclient"
  ],
  development: [
    "development", "ide", "texteditor", "debugger", "revisioncontrol",
    "translation", "guidesigner", "webdevelopment", "terminalemulator", "building"
  ],
  media: [
    "audiovideo", "audio", "video", "graphics", "photography",
    "rastergraphics", "vectorgraphics", "player", "recorder", "music",
    "midi", "2dgraphics", "3dgraphics", "art", "scanning", "audiovideoediting"
  ],
  productivity: [
    "office", "wordprocessor", "spreadsheet", "presentation",
    "publishing", "finance", "calendar", "contactmanagement", "viewer", "dictionary"
  ],
  utilities: [
    "system", "utility", "settings", "packagemanager", "monitor",
    "security", "archiving", "compression", "filetools", "accessibility",
    "core", "hardwaresettings", "filemanager", "filesystem", "calculator"
  ],
  games: [
    "game", "actiongame", "adventuregame", "arcadegame", "boardgame",
    "cardgame", "emulator", "logicgame", "roleplaying", "shooter",
    "simulation", "sportsgame", "strategygame"
  ]
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

function getCategoryForEntry(entry) {
  if (!entry) return "utilities"
  var cats = normalizeCategories(entry.categories)
  var name = String(entry.name || "").toLowerCase()
  var id = String(entry.id || "").toLowerCase()
  var comment = String(entry.comment || "").toLowerCase()

  for (var categoryKey in CATEGORY_MAP) {
    var keywords = CATEGORY_MAP[categoryKey]
    for (var i = 0; i < cats.length; i++) {
      if (keywords.indexOf(cats[i]) !== -1) return categoryKey
    }
  }

  // Fallback heuristics based on name and ID keywords
  if (/browser|web|chat|discord|whatsapp|signal|slack|telegram|mail|youtube|hey|zoom|messages/i.test(name + " " + id + " " + comment)) {
    return "internet"
  }
  if (/code|nvim|editor|studio|dev|git|terminal|debug/i.test(name + " " + id + " " + comment)) {
    return "development"
  }
  if (/media|video|audio|music|photo|player|mpv|obs|pinta|kdenlive|imv|spotify/i.test(name + " " + id + " " + comment)) {
    return "media"
  }
  if (/office|calc|writer|document|notes|obsidian|contacts|calendar|basecamp/i.test(name + " " + id + " " + comment)) {
    return "productivity"
  }
  if (/game|steam|retro|play|heroic|lutris|battlenet/i.test(name + " " + id + " " + comment)) {
    return "games"
  }

  return "utilities"
}

function filterEntries(entries, categoryId, searchQuery) {
  var list = entries || []
  var query = String(searchQuery || "").trim().toLowerCase()
  var selectedCategory = String(categoryId || "all")

  var filtered = []
  for (var i = 0; i < list.length; i++) {
    var entry = list[i]
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
    getCategoryForEntry: getCategoryForEntry,
    filterEntries: filterEntries
  }
}
