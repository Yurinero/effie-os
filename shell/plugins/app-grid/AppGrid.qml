import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "AppCategories.js" as AppCategories

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string selectedCategory: "all"
  property string searchQuery: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property var allApps: []

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
  property int headerHeight: Math.max(Style.space(40), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int cardWidth: Math.min(Style.space(920), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(640), panel.height - Style.gapsOut * 2)

  function open(payloadJson) {
    root.opened = true
    root.selectedCategory = "all"
    root.searchQuery = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (root.shell && root.shell.appLibrary) {
      root.shell.appLibrary.refreshIcons()
    }
    root.reloadApps()
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide((root.manifest && root.manifest.id) || "omarchy.app-grid")
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function reloadApps() {
    if (root.shell && root.shell.appLibrary) {
      root.allApps = root.shell.appLibrary.sortedEntries("")
    } else {
      root.allApps = []
    }
    root.rebuildGrid()
  }

  function rebuildGrid() {
    var filtered = AppCategories.filterEntries(root.allApps, root.selectedCategory, root.searchQuery)
    gridModel.clear()
    for (var i = 0; i < filtered.length; i++) {
      var item = filtered[i]
      var name = String((item && item.name) || (item && item.id) || "")
      var genericName = String((item && item.genericName) || "")
      var icon = String((item && item.icon) || "")
      var id = String((item && item.id) || "")
      var category = AppCategories.getCategoryForEntry(item)

      gridModel.append({
        appId: id,
        name: name,
        genericName: genericName,
        icon: icon,
        category: category,
        index: i
      })
    }

    if (gridModel.count === 0) {
      root.selectedIndex = 0
    } else if (root.selectedIndex >= gridModel.count) {
      root.selectedIndex = gridModel.count - 1
    } else if (root.selectedIndex < 0) {
      root.selectedIndex = 0
    }

    Qt.callLater(function() {
      if (gridModel.count > 0 && appGridView) {
        appGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain)
      }
    })
  }

  function launchApp(id, name) {
    if (!id) return
    root.dismiss()
    if (root.shell && root.shell.appLibrary) {
      root.shell.appLibrary.launch(id, name)
    } else {
      Util.execDetached("uwsm-app -- gtk-launch " + Util.shellQuote(id + ".desktop"))
    }
  }

  function activateCurrent() {
    if (gridModel.count === 0 || root.selectedIndex < 0 || root.selectedIndex >= gridModel.count) return
    var item = gridModel.get(root.selectedIndex)
    root.launchApp(item.appId, item.name)
  }

  function moveSelection(dx, dy) {
    if (gridModel.count === 0) return
    root.cursorActive = true
    var cols = Math.max(1, Math.floor(appGridView.width / appGridView.cellWidth))
    var nextIndex = root.selectedIndex + dx + (dy * cols)
    if (nextIndex < 0) nextIndex = 0
    if (nextIndex >= gridModel.count) nextIndex = gridModel.count - 1
    root.selectedIndex = nextIndex
    appGridView.positionViewAtIndex(root.selectedIndex, GridView.Contain)
  }

  function selectCategory(catId) {
    root.selectedCategory = catId
    root.selectedIndex = 0
    root.rebuildGrid()
    if (keyCatcher) keyCatcher.forceActiveFocus()
  }

  function cycleCategory(delta) {
    var cats = AppCategories.CATEGORIES
    var currentIdx = 0
    for (var i = 0; i < cats.length; i++) {
      if (cats[i].id === root.selectedCategory) {
        currentIdx = i
        break
      }
    }
    var nextIdx = (currentIdx + delta + cats.length) % cats.length
    root.selectCategory(cats[nextIdx].id)
  }

  Connections {
    target: (root.shell && root.shell.appLibrary) ? root.shell.appLibrary : null
    function onAppsChanged() {
      if (root.opened) root.reloadApps()
    }
  }

  ListModel { id: gridModel }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-app-grid"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: root.cardWidth
      height: root.cardHeight
      color: root.background
      borderSpec: root.borderSpec
      radius: root.cornerRadius
      padding: root.contentMargin

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.searchQuery.length > 0) {
              root.searchQuery = ""
              root.rebuildGrid()
            } else {
              root.dismiss()
            }
            event.accepted = true
          } else if (event.key === Qt.Key_Tab) {
            root.cycleCategory(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Backtab) {
            root.cycleCategory(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateCurrent()
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.moveSelection(-1, 0)
            event.accepted = true
          } else if (event.key === Qt.Key_Right) {
            root.moveSelection(1, 0)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveSelection(0, -1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveSelection(0, 1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.moveSelection(0, -4)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.moveSelection(0, 4)
            event.accepted = true
          } else if (Util.editsFilter(event, root.searchQuery)) {
            root.searchQuery = Util.editedFilter(event, root.searchQuery)
            root.selectedIndex = 0
            root.rebuildGrid()
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.searchQuery = root.searchQuery + event.text
            root.selectedIndex = 0
            root.rebuildGrid()
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.spacing.md

        // 1. Header with search bar and close button
        Row {
          width: parent.width
          height: root.headerHeight
          spacing: Style.spacing.md

          // Title & Icon
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.sm
            width: Style.space(160)

            Text {
              text: "󰀻"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Applications"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Search Field surface
          BorderSurface {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(160) - closeBtn.width - Style.spacing.md * 2
            height: root.headerHeight
            radius: root.cornerRadius
            color: Style.controlFill(true, false, root.foreground, root.accent)
            borderSpec: Border.controlSpec("focus", root.foreground, root.accent)

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.spacing.controlPaddingX
              anchors.rightMargin: Style.spacing.controlPaddingX
              spacing: Style.spacing.sm

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "🔍"
                font.pixelSize: Style.font.body
                opacity: 0.6
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Style.space(60)
                text: root.searchQuery || "Type to search applications..."
                color: root.foreground
                opacity: root.searchQuery ? 1.0 : 0.45
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Button {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.searchQuery.length > 0
                text: "✕"
                horizontalPadding: 4
                verticalPadding: 2
                onClicked: {
                  root.searchQuery = ""
                  root.rebuildGrid()
                  keyCatcher.forceActiveFocus()
                }
              }
            }
          }

          // Close Button
          Button {
            id: closeBtn
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            horizontalPadding: Style.spacing.controlPaddingX
            onClicked: root.dismiss()
          }
        }

        // 2. Category Filter Pills
        Row {
          width: parent.width
          spacing: Style.spacing.xs

          Repeater {
            model: AppCategories.CATEGORIES
            delegate: Button {
              required property var modelData
              text: modelData.icon + " " + modelData.label
              selected: root.selectedCategory === modelData.id
              onClicked: root.selectCategory(modelData.id)
            }
          }
        }

        // Separator
        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
        }

        // 3. Main Applications Grid
        Item {
          width: parent.width
          height: card.height - card.contentTopInset - card.contentBottomInset - Style.space(160)

          GridView {
            id: appGridView
            anchors.fill: parent
            clip: true
            cellWidth: Math.floor(width / Math.max(3, Math.floor(width / Style.space(145))))
            cellHeight: Style.space(130)
            model: gridModel
            focus: true

            delegate: Item {
              required property string appId
              required property string name
              required property string genericName
              required property string icon
              required property string category
              required property int index

              width: appGridView.cellWidth
              height: appGridView.cellHeight

              readonly property bool isSelected: root.cursorActive && (root.selectedIndex === index)

              BorderSurface {
                anchors.fill: parent
                anchors.margins: Style.spacing.xs
                radius: root.cornerRadius
                color: isSelected ? root.selectedBackground : (tileMouseArea.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06) : "transparent")
                borderSpec: Border.controlSpec(isSelected ? "focus" : (tileMouseArea.containsMouse ? "hover" : "normal"), root.foreground, root.accent)

                Column {
                  anchors.centerIn: parent
                  spacing: Style.spacing.xs
                  width: parent.width - Style.spacing.sm * 2

                  // App Icon
                  Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Style.space(48)
                    height: Style.space(48)
                    sourceSize.width: Style.space(48)
                    sourceSize.height: Style.space(48)
                    fillMode: Image.PreserveAspectFit
                    source: root.shell && root.shell.appLibrary ? root.shell.appLibrary.iconSource(icon) : ""
                    smooth: true
                  }

                  // App Name
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: name
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    color: isSelected ? root.selectedText : root.foreground
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                  }

                  // Generic Name / Category
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: genericName.length > 0 ? genericName : category
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: isSelected ? root.selectedText : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: tileMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: {
                    root.selectedIndex = index
                    root.cursorActive = true
                  }
                  onClicked: {
                    root.launchApp(appId, name)
                  }
                }
              }
            }
          }

          // Empty state message
          Column {
            anchors.centerIn: parent
            spacing: Style.spacing.sm
            visible: gridModel.count === 0

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰄱"
              font.pixelSize: Style.space(48)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.4)
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "No applications found"
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
            }
          }
        }

        // 4. Footer info and keyboard guide
        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: gridModel.count + " applications"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ Open   •   Tab Category   •   Esc Close   •   ↑↓←→ Navigate"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
          }
        }
      }
    }
  }
}
