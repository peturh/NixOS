// TLP power-profile widget for Noctalia.
//
// Polls `tlp-ctl get` every few seconds to display the current profile
// (low / medium / performance) and cycles it on left-click. Right-click
// jumps straight to performance.
//
// Requires the `tlp-ctl` binary on PATH; the NixOS Noctalia module ships
// it via writeShellApplication around modules/desktop/hyprland/scripts/
// tlp-ctl.sh. The polkit rule in modules/programs/misc/tlp/default.nix
// grants the `power` group password-less pkexec, so `tlp-ctl set ...`
// works without a prompt.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  readonly property int pollIntervalMs:
    pluginApi?.pluginSettings?.pollIntervalMs ||
    pluginApi?.manifest?.metadata?.defaultSettings?.pollIntervalMs ||
    5000

  // Current TLP profile: "low", "medium", "performance", or "" while loading.
  property string profile: ""

  readonly property string iconName: {
    if (root.profile === "performance") return "rocket"
    if (root.profile === "medium") return "scale"
    if (root.profile === "low") return "leaf"
    return "bolt"
  }

  readonly property color accentColor: {
    if (root.profile === "performance") return Color.mPrimary
    if (root.profile === "medium") return Color.mTertiary
    if (root.profile === "low") return Color.mOnSurfaceVariant
    return Color.mOnSurfaceVariant
  }

  // Icon-only widget: capsule is square (height == capsuleHeight) on
  // horizontal bars and width-locked on vertical bars.
  readonly property real contentWidth: capsuleHeight
  readonly property real contentHeight: capsuleHeight
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // --- Profile polling -----------------------------------------------------

  Process {
    id: getProcess
    command: ["tlp-ctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = String(text || "").trim()
        if (out === "low" || out === "medium" || out === "performance") {
          root.profile = out
        }
      }
    }
  }

  function refresh() {
    if (!getProcess.running) {
      getProcess.running = true
    }
  }

  Component.onCompleted: refresh()

  Timer {
    interval: root.pollIntervalMs
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  // --- Profile mutation ----------------------------------------------------

  Process {
    id: cycleProcess
    command: ["tlp-ctl", "cycle"]
    onExited: root.refresh()
  }

  Process {
    id: setPerfProcess
    command: ["tlp-ctl", "set", "performance"]
    onExited: root.refresh()
  }

  function cycle() {
    if (!cycleProcess.running) {
      cycleProcess.running = true
    }
  }

  function setPerformance() {
    if (!setPerfProcess.running) {
      setPerfProcess.running = true
    }
  }

  // --- Visual capsule ------------------------------------------------------

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      anchors.centerIn: parent
      icon: root.iconName
      color: root.accentColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.cycle()
      } else if (mouse.button === Qt.RightButton) {
        root.setPerformance()
      }
    }
  }
}
