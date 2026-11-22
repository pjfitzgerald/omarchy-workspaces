import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "pjf.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceByName(name) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].name === name) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function toggleScratchpad() {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.workspace.toggle_special(\"scratchpad\")"))
  }

  readonly property var scratchpad: workspaceByName("special:scratchpad")
  readonly property int scratchpadCount: scratchpad !== null ? scratchpad.toplevels.values.length : 0
  readonly property bool scratchpadVisible: scratchpadCount > 0 || shownSpecial === "special:scratchpad"

  // The special workspace this bar's monitor is showing ("" when none). Hyprland keeps the regular
  // workspace focused while a special one is open, so Hyprland.focusedWorkspace can't tell us;
  // seed from the monitor's IPC object and follow `activespecial` events.
  readonly property var monitor: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  }
  property string shownSpecial: ""
  readonly property bool orchShown: shownSpecial === "special:agent-orch"

  function syncSpecial() {
    var ipc = root.monitor ? root.monitor.lastIpcObject : null
    root.shownSpecial = ipc && ipc.specialWorkspace && ipc.specialWorkspace.name ? String(ipc.specialWorkspace.name) : ""
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name !== "activespecial" || !root.monitor) return
      var data = String(event.data)
      var comma = data.lastIndexOf(",")
      if (data.slice(comma + 1) === root.monitor.name) root.shownSpecial = data.slice(0, comma)
    }
  }
  // lastIpcObject has no change signal: refresh, then read it once the reply has landed.
  function seedSpecial() { Hyprland.refreshMonitors(); seedTimer.restart() }
  Timer { id: seedTimer; interval: 500; onTriggered: root.syncSpecial() }
  onMonitorChanged: seedSpecial()
  Component.onCompleted: seedSpecial()

  function toggleOrch() {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.workspace.toggle_special(\"agent-orch\")"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length + (root.scratchpadVisible ? 1 : 0) + (root.orchShown ? 1 : 0)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool current: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        // Under an open special workspace the regular one isn't what you're looking at.
        readonly property bool focused: current && root.shownSpecial === ""

        bar: root.bar
        text: focused ? "󱓻" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || current ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }

    WidgetButton {
      visible: root.scratchpadVisible
      bar: root.bar
      text: root.scratchpadCount > 1 ? " " + root.scratchpadCount : ""
      active: root.shownSpecial === "special:scratchpad"
      opacity: active ? 1 : 0.8
      horizontalMargin: 6
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : Style.space(root.scratchpadCount > 1 ? 28 : 20)
      fixedHeight: root.barSize
      onPressed: function() { root.toggleScratchpad() }
    }

    // The orchestrator popout (special:agent-orch), shown only while it's open.
    WidgetButton {
      visible: root.orchShown
      bar: root.bar
      text: ""  // nf-fa-sitemap, same glyph as the pjf.agent-orch bar icon
      active: true
      horizontalMargin: 6
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : Style.space(20)
      fixedHeight: root.barSize
      onPressed: function() { root.toggleOrch() }
    }
  }
}
