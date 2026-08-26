import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property int selectedIndex: 0
  property var workspaceList: []

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property int cornerRadius: Style.cornerRadius
  property int contentMargin: Style.spacing.panelPadding

  function open(payloadJson) {
    root.opened = true
    if (root.shell && root.shell.appLibrary && typeof root.shell.appLibrary.refreshIcons === "function") {
      root.shell.appLibrary.refreshIcons()
    }
    root.reloadWorkspaces()

    // Find current focused workspace index
    var focusedId = (Hyprland.focusedWorkspace !== null) ? Hyprland.focusedWorkspace.id : 1
    var initialIdx = 0
    for (var i = 0; i < root.workspaceList.length; i++) {
      if (root.workspaceList[i].id === focusedId) {
        initialIdx = (i + 1) % root.workspaceList.length
        break
      }
    }
    root.selectedIndex = initialIdx

    Qt.callLater(function() {
      if (focusCatcher) {
        focusCatcher.forceActiveFocus()
      }
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide((root.manifest && root.manifest.id) || "omarchy.workspace-switcher")
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function findDesktopIcon(appClass, title) {
    var rawClass = String(appClass || "").trim().toLowerCase()
    var rawTitle = String(title || "").trim().toLowerCase()
    if (!rawClass && !rawTitle) return ""

    var apps = (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values) ? DesktopEntries.applications.values : []

    // 1. Exact match on entry.id or entry.name or entry.icon
    for (var i = 0; i < apps.length; i++) {
      var app = apps[i]
      if (!app) continue
      var appId = String(app.id || "").toLowerCase()
      var appName = String(app.name || "").toLowerCase()
      var appIcon = String(app.icon || "").toLowerCase()

      if (rawClass.length > 0 && (appId === rawClass || appName === rawClass || appIcon === rawClass)) {
        return app.icon
      }
    }

    // 2. Substring / prefix / suffix match (e.g. "godot_engine" -> "godot", "zen-alpha" -> "zen-browser", "code-oss" -> "code")
    for (var j = 0; j < apps.length; j++) {
      var entry = apps[j]
      if (!entry) continue
      var eId = String(entry.id || "").toLowerCase()
      var eName = String(entry.name || "").toLowerCase()
      var eIcon = String(entry.icon || "").toLowerCase()

      if (rawClass.length > 0) {
        if (rawClass.indexOf(eId) !== -1 || eId.indexOf(rawClass) !== -1) return entry.icon
        if (rawClass.indexOf(eIcon) !== -1 || eIcon.indexOf(rawClass) !== -1) return entry.icon
        if (rawClass.indexOf(eName) !== -1 || eName.indexOf(rawClass) !== -1) return entry.icon
      }

      if (rawTitle.length > 0) {
        if (rawTitle.indexOf(eName) !== -1 || eName.indexOf(rawTitle) !== -1) return entry.icon
        if (rawTitle.indexOf(eId) !== -1) return entry.icon
      }
    }

    return ""
  }

  function resolveIcon(appClass, title) {
    var raw = String(appClass || "").trim()
    var rawTitle = String(title || "").trim()
    if (!raw && !rawTitle) return ""

    // 1. Look up authoritative desktop entry icon
    var desktopIcon = root.findDesktopIcon(raw, rawTitle)
    if (desktopIcon) {
      var dSrc = ""
      if (root.shell && root.shell.appLibrary) {
        dSrc = root.shell.appLibrary.iconSource(desktopIcon)
      }
      if (!dSrc || dSrc.indexOf("application-x-executable") !== -1) {
        var themed = Quickshell.iconPath(desktopIcon, true)
        if (themed) dSrc = themed
      }
      if (dSrc && dSrc.indexOf("application-x-executable") === -1) {
        return dSrc.charAt(0) === "/" ? Util.fileUrl(dSrc) : dSrc
      }
    }

    // 2. Direct AppLibrary resolution
    var src = ""
    if (root.shell && root.shell.appLibrary && raw) {
      src = root.shell.appLibrary.iconSource(raw)
      if (!src || src.indexOf("application-x-executable") !== -1) {
        var lowerSrc = root.shell.appLibrary.iconSource(raw.toLowerCase())
        if (lowerSrc && lowerSrc.indexOf("application-x-executable") === -1) src = lowerSrc
      }
    }

    // 3. Quickshell themed path fallback
    if (!src || src.indexOf("application-x-executable") !== -1) {
      if (raw) {
        var themedRaw = Quickshell.iconPath(raw, true)
        if (!themedRaw) themedRaw = Quickshell.iconPath(raw.toLowerCase(), true)
        if (themedRaw) src = themedRaw
      }
      if (!src && rawTitle) {
        var themedTitle = Quickshell.iconPath(rawTitle.toLowerCase(), true)
        if (themedTitle) src = themedTitle
      }
    }

    if (src && src.charAt(0) === "/") {
      src = Util.fileUrl(src)
    }

    return src
  }

  function reloadWorkspaces() {
    var values = (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
    var ids = [1, 2, 3, 4, 5]

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) {
        ids.push(id)
      }
    }
    ids.sort(function(a, b) { return a - b })

    var list = []
    for (var j = 0; j < ids.length; j++) {
      var wId = ids[j]
      var ws = null
      for (var k = 0; k < values.length; k++) {
        if (values[k].id === wId) {
          ws = values[k]
          break
        }
      }

      var icons = []
      var windowCount = 0
      if (ws !== null && ws.toplevels && ws.toplevels.values) {
        var toplevels = ws.toplevels.values
        windowCount = toplevels.length
        for (var t = 0; t < toplevels.length; t++) {
          var tl = toplevels[t]
          var appClass = String((tl && (tl.waylandClass || tl.class || tl.initialClass || tl.appId)) || "")
          var title = String((tl && (tl.title || tl.initialTitle)) || appClass)
          var iconSrc = root.resolveIcon(appClass, title)

          icons.push({
            appClass: appClass,
            iconSource: iconSrc,
            title: title
          })
        }
      }

      var isFocused = (Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wId)
      list.push({
        id: wId,
        label: (wId === 10) ? "10" : String(wId),
        isFocused: isFocused,
        windowCount: windowCount,
        icons: icons
      })
    }

    root.workspaceList = list
  }

  function moveSelection(delta) {
    if (root.workspaceList.length === 0) return
    var nextIdx = (root.selectedIndex + delta + root.workspaceList.length) % root.workspaceList.length
    root.selectedIndex = nextIdx
  }

  function selectById(wId) {
    for (var i = 0; i < root.workspaceList.length; i++) {
      if (root.workspaceList[i].id === wId) {
        root.selectedIndex = i
        break
      }
    }
  }

  function activateSelected() {
    if (root.selectedIndex >= 0 && root.selectedIndex < root.workspaceList.length) {
      root.activateWorkspace(root.workspaceList[root.selectedIndex].id)
    } else {
      root.dismiss()
    }
  }

  function activateWorkspace(id) {
    if (id !== undefined && id !== null) {
      Util.execDetached("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
    }
    root.dismiss()
  }

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() {
      if (root.opened) root.reloadWorkspaces()
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-workspace-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Scrim overlay
    Rectangle {
      anchors.fill: parent
      color: root.scrim

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }
    }

    // Keyboard focus catcher
    Item {
      id: focusCatcher
      focus: true

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
          root.moveSelection(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
          root.moveSelection(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          root.activateSelected()
          event.accepted = true
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
          var targetId = event.key - Qt.Key_0
          root.activateWorkspace(targetId)
          event.accepted = true
        } else if (event.key === Qt.Key_0) {
          root.activateWorkspace(10)
          event.accepted = true
        }
      }
    }

    // Main Floating Switcher Card
    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(contentRow.implicitWidth + card.contentLeftInset + card.contentRightInset, panel.width - Style.gapsOut * 2)
      height: Style.space(210)
      color: root.background
      borderSpec: root.borderSpec
      radius: root.cornerRadius
      padding: root.contentMargin

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        anchors.centerIn: parent
        spacing: Style.spacing.md

        // Header Title
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.spacing.sm

          Text {
            text: "󰍹"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Workspaces"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Workspace Cards Row
        Row {
          id: contentRow
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.spacing.sm

          Repeater {
            model: root.workspaceList

            delegate: Item {
              id: wsTile
              required property var modelData
              required property int index

              width: Style.space(145)
              height: Style.space(120)

              readonly property bool isSelected: (root.selectedIndex === index)
              readonly property bool isFocused: modelData.isFocused

              BorderSurface {
                anchors.fill: parent
                radius: root.cornerRadius
                color: isSelected ? root.selectedBackground : (tileMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.03))
                borderSpec: Border.controlSpec(isSelected ? "focus" : (tileMouse.containsMouse ? "hover" : "normal"), root.foreground, root.accent)

                Column {
                  anchors.fill: parent
                  anchors.margins: Style.spacing.xs
                  spacing: Style.spacing.xs

                  // Workspace Header (Badge & Window Count)
                  Row {
                    width: parent.width
                    spacing: Style.spacing.xs

                    Rectangle {
                      width: Style.space(24)
                      height: Style.space(24)
                      radius: width / 2
                      color: isSelected ? root.accent : (isFocused ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15))

                      Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        color: isSelected ? Color.menu.background : root.foreground
                      }
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: modelData.windowCount > 0 ? (modelData.windowCount + (modelData.windowCount === 1 ? " app" : " apps")) : "empty"
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      color: isSelected ? root.selectedText : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
                      elide: Text.ElideRight
                      width: parent.width - Style.space(32)
                    }
                  }

                  // Active App Icons Row
                  Item {
                    width: parent.width
                    height: Style.space(56)

                    Row {
                      anchors.centerIn: parent
                      spacing: Style.spacing.xs
                      visible: modelData.icons.length > 0

                      Repeater {
                        model: modelData.icons.slice(0, 3)

                        delegate: Item {
                          required property var modelData
                          width: Style.space(36)
                          height: Style.space(36)

                          Image {
                            id: appImg
                            anchors.fill: parent
                            sourceSize.width: Style.space(36)
                            sourceSize.height: Style.space(36)
                            fillMode: Image.PreserveAspectFit
                            source: modelData.iconSource
                            smooth: true
                            asynchronous: true
                          }

                          Text {
                            anchors.centerIn: parent
                            visible: modelData.iconSource.length === 0 || appImg.status === Image.Error
                            text: "󰀻"
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.title
                            color: isSelected ? root.selectedText : root.foreground
                          }
                        }
                      }

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.icons.length > 3
                        text: "+" + (modelData.icons.length - 3)
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        color: isSelected ? root.selectedText : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
                      }
                    }

                    // Empty state dot
                    Rectangle {
                      anchors.centerIn: parent
                      visible: modelData.icons.length === 0
                      width: Style.space(6)
                      height: Style.space(6)
                      radius: 3
                      color: isSelected ? root.selectedText : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)
                    }
                  }
                }

                MouseArea {
                  id: tileMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: {
                    root.selectedIndex = index
                  }
                  onClicked: {
                    root.activateWorkspace(modelData.id)
                  }
                }
              }
            }
          }
        }

        // Navigation Footer Hints
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Tab / ←→ Navigate   •   ↵ / Click Switch   •   1–9 Jump   •   Esc Cancel"
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
        }
      }
    }
  }
}
