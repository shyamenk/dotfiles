import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
  id: root
  moduleName: "io.github.shyamenk.cmf-buds"
  ipcTarget: "io.github.shyamenk.cmf-buds"

  readonly property string helperPath: Qt.resolvedUrl("bin/cmfbuds.py").toString().replace("file://", "")

  property bool connected: false
  property string errorText: ""
  property string ancMode: ""
  property var battery: ({})
  property string eqPreset: ""
  property var bass: ({ enabled: false, level: 3 })
  property var gestures: ({ left: {}, right: {} })

  property string page: "sound"
  property string gestureSide: "left"
  property var queue: []

  // Order is the display order in the panel (3 x 2 grid).
  readonly property var modes: [
    { id: "high", label: "Cancel", icon: 0xF02CB },
    { id: "adaptive", label: "Adaptive", icon: 0xF0068 },
    { id: "transparency", label: "Aware", icon: 0xF07C5 },
    { id: "mid", label: "Medium", icon: 0xF0580 },
    { id: "low", label: "Light", icon: 0xF057F },
    { id: "off", label: "Off", icon: 0xF0581 }
  ]

  readonly property var eqPresets: [
    { id: "balanced", label: "Balanced" },
    { id: "more_bass", label: "Bass" },
    { id: "more_treble", label: "Treble" },
    { id: "voice", label: "Voice" }
  ]

  readonly property var gestureTypes: [
    { id: "double-pinch", label: "Double pinch" },
    { id: "triple-pinch", label: "Triple pinch" },
    { id: "pinch-hold", label: "Pinch and hold" },
    { id: "double-pinch-hold", label: "Double pinch and hold" }
  ]

  readonly property var gestureActions: [
    { value: "no-action", label: "No action" },
    { value: "skip-back", label: "Previous track" },
    { value: "skip-forward", label: "Next track" },
    { value: "voice-assistant", label: "Voice assistant" },
    { value: "volume-up", label: "Volume up" },
    { value: "volume-down", label: "Volume down" },
    { value: "noise-control", label: "Noise control" },
    { value: "noise-control-cycle", label: "Cycle noise control" },
    { value: "noise-control-off-anc", label: "Toggle cancel / off" },
    { value: "noise-control-trans-off", label: "Toggle aware / off" }
  ]

  function glyph(codePoint) { return String.fromCodePoint(codePoint) }

  function modeIcon(id) {
    for (var i = 0; i < modes.length; i++)
      if (modes[i].id === id) return glyph(modes[i].icon)
    return glyph(0xF02CB)
  }

  readonly property string barIcon: connected ? modeIcon(ancMode) : glyph(0xF07CE)

  function applyStatus(text) {
    var data
    try { data = JSON.parse(text) } catch (e) { return }
    connected = !!data.connected
    errorText = data.error || ""
    if (!connected) return
    ancMode = data.anc || ""
    battery = data.battery || {}
    if (data.eq !== undefined) eqPreset = data.eq || ""
    if (data.bass !== undefined) bass = data.bass
    if (data.gestures !== undefined) gestures = data.gestures
  }

  function idle() { return !statusProc.running && !actionProc.running && queue.length === 0 }

  function refresh(command) {
    if (!idle()) return
    statusProc.command = ["python3", helperPath, command || "status"]
    statusProc.running = true
  }

  // Commands queue so quick repeated presses (bass +/-) are not dropped.
  function send(args) {
    queue = queue.concat([args])
    nextAction()
  }

  function nextAction() {
    if (actionProc.running || queue.length === 0) return
    var args = queue[0]
    queue = queue.slice(1)
    actionProc.command = ["python3", helperPath].concat(args)
    actionProc.running = true
  }

  function setMode(id) { send(["anc", id]) }
  function setEq(id) { send(["eq", id]) }
  function setBassLevel(level) { send(["bass", String(Math.max(0, Math.min(5, level)))]) }
  function toggleBass() { send(["bass", bass.enabled ? "off" : "on"]) }
  function setGesture(side, type, action) { send(["gesture", side, type, action]) }

  function gestureAction(side, type) {
    var group = gestures[side]
    return group && group[type] ? group[type] : "no-action"
  }

  function levelText(part) {
    var item = battery[part]
    return item ? item.level + "%" + (item.charging ? " ⚡" : "") : "—"
  }

  function levelFraction(part) {
    var item = battery[part]
    return item ? item.level / 100 : 0
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) refresh("settings")

  Process {
    id: statusProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyStatus(text) }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyStatus(text) }
    onExited: root.nextAction()
  }

  Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh("status") }
  Timer { interval: 4000; running: root.opened; repeat: true; onTriggered: root.refresh("status") }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barIcon
    tooltipText: root.connected ? "CMF Buds Pro 2" : "CMF Buds Pro 2 (not connected)"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Row {
          width: parent.width
          spacing: Style.space(14)

          Text {
            textFormat: Text.PlainText
            text: root.barIcon
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "CMF Buds Pro 2"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              text: (root.connected ? "CONNECTED" : (root.errorText || "NOT CONNECTED")).toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: column.width - Style.space(60)
            }
          }
        }

        Row {
          id: tabs
          width: parent.width
          spacing: Style.space(6)
          readonly property real cellWidth: (width - spacing) / 2

          Repeater {
            model: [{ id: "sound", label: "Sound" }, { id: "gestures", label: "Gestures" }]
            Button {
              required property var modelData
              width: tabs.cellWidth
              text: modelData.label
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              bordered: true
              active: root.page === modelData.id
              onClicked: root.page = modelData.id
            }
          }
        }

        // ---------- Sound page ----------
        Column {
          visible: root.page === "sound"
          width: parent.width
          spacing: Style.space(14)

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "NOISE CONTROL"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Grid {
              id: modeGrid
              width: parent.width
              columns: 3
              spacing: Style.space(6)
              readonly property real cellWidth: (width - spacing * (columns - 1)) / columns

              Repeater {
                model: root.modes
                Button {
                  required property var modelData
                  width: modeGrid.cellWidth
                  iconText: root.glyph(modelData.icon)
                  iconSize: Style.font.title
                  text: modelData.label
                  fontSize: Style.font.bodySmall
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                  horizontalPadding: Style.spacing.controlPaddingX
                  verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                  bordered: true
                  enabled: root.connected
                  active: root.ancMode === modelData.id
                  onClicked: root.setMode(modelData.id)
                }
              }
            }
          }

          PanelSeparator { foreground: root.bar.foreground }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "EQUALIZER"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Row {
              id: eqRow
              width: parent.width
              spacing: Style.space(6)
              readonly property real cellWidth: (width - spacing * (root.eqPresets.length - 1)) / root.eqPresets.length

              Repeater {
                model: root.eqPresets
                Button {
                  required property var modelData
                  width: eqRow.cellWidth
                  text: modelData.label
                  fontSize: Style.font.bodySmall
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                  horizontalPadding: Style.spacing.controlPaddingX
                  verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                  bordered: true
                  enabled: root.connected
                  active: root.eqPreset === modelData.id
                  onClicked: root.setEq(modelData.id)
                }
              }
            }

            Row {
              id: bassRow
              width: parent.width
              spacing: Style.space(6)

              Text {
                id: bassLabel
                text: "Bass enhance"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
                width: bassRow.width - bassToggle.width - bassMinus.width - bassValue.width - bassPlus.width - bassRow.spacing * 4
                elide: Text.ElideRight
              }

              Button {
                id: bassMinus
                width: Style.space(32)
                text: "−"
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                bordered: true
                enabled: root.connected && root.bass.enabled && root.bass.level > 0
                onClicked: root.setBassLevel(root.bass.level - 0.5)
              }

              Text {
                id: bassValue
                width: Style.space(34)
                horizontalAlignment: Text.AlignHCenter
                text: root.bass.enabled ? Number(root.bass.level).toFixed(1) : "—"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
              }

              Button {
                id: bassPlus
                width: Style.space(32)
                text: "+"
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                bordered: true
                enabled: root.connected && root.bass.enabled && root.bass.level < 5
                onClicked: root.setBassLevel(root.bass.level + 0.5)
              }

              Button {
                id: bassToggle
                width: Style.space(52)
                text: root.bass.enabled ? "On" : "Off"
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                bordered: true
                enabled: root.connected
                active: root.bass.enabled
                onClicked: root.toggleBass()
              }
            }
          }

          PanelSeparator { foreground: root.bar.foreground }

          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "BATTERY"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Repeater {
              model: [
                { part: "left", label: "Left" },
                { part: "right", label: "Right" },
                { part: "case", label: "Case" }
              ]

              Row {
                required property var modelData
                width: column.width
                spacing: Style.space(10)
                opacity: root.battery[modelData.part] ? 1 : 0.4

                Text {
                  width: Style.space(48)
                  text: modelData.label
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                  width: parent.width - Style.space(48) - Style.space(64) - parent.spacing * 2
                  height: Style.space(6)
                  anchors.verticalCenter: parent.verticalCenter

                  Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
                  }

                  Rectangle {
                    height: parent.height
                    radius: height / 2
                    color: root.bar.foreground
                    width: Math.max(height, parent.width * root.levelFraction(modelData.part))
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                  }
                }

                Text {
                  width: Style.space(64)
                  horizontalAlignment: Text.AlignRight
                  textFormat: Text.PlainText
                  text: root.levelText(modelData.part)
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }

        // ---------- Gestures page ----------
        Column {
          visible: root.page === "gestures"
          width: parent.width
          spacing: Style.space(14)

          Row {
            id: sideRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing) / 2

            Repeater {
              model: [{ id: "left", label: "Left bud" }, { id: "right", label: "Right bud" }]
              Button {
                required property var modelData
                width: sideRow.cellWidth
                text: modelData.label
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                horizontalPadding: Style.spacing.controlPaddingX
                verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
                bordered: true
                active: root.gestureSide === modelData.id
                onClicked: root.gestureSide = modelData.id
              }
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(10)

            Repeater {
              model: root.gestureTypes

              Item {
                required property var modelData
                width: column.width
                height: Style.spacing.controlHeight

                Text {
                  text: modelData.label
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - gestureMenu.width - Style.space(10)
                  elide: Text.ElideRight
                }

                Dropdown {
                  id: gestureMenu
                  width: Style.space(170)
                  anchors.right: parent.right
                  showLabel: false
                  enabled: root.connected
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                  options: root.gestureActions
                  value: root.gestureAction(root.gestureSide, modelData.id)
                  onChanged: function(v) { root.setGesture(root.gestureSide, modelData.id, v) }
                }
              }
            }
          }
        }
      }
    }
  }
}
