import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "wwan-ctl"

    // ==== WWAN state ====
    //
    // Mirrors `wwan-ctl get --json`. The property names here deliberately
    // avoid QML reserved/built-in identifiers — `signal` is a keyword used
    // to declare signals, `state` is a built-in Item property used by the
    // QML state machine, and `connect` is a method on every signal object.
    // Earlier drafts used those names directly and the bindings silently
    // broke (the pill got stuck on the first read because root.state never
    // changed). The mapping from JSON keys to QML properties:
    //   present     → present     bool
    //   state       → modemState  string  (absent | disabled | registered |
    //                                      connecting | connected | …)
    //   signal      → signalPct   int     (0-100)
    //   tech        → tech        string  (lte | umts | gsm | …)
    //   operator    → operator    string  ("Telenor SE")
    //   ip          → ip          string  (IPv4 with CIDR, "" when down)
    //   connected   → connected   bool    (convenience)
    property bool present: false
    property string modemState: "absent"
    property int signalPct: 0
    property string tech: ""
    property string operator: ""
    property string ip: ""
    property bool connected: false
    property bool busy: false
    property int pollIntervalMs: 5000

    function refresh() {
        Proc.runCommand(
            "wwanCtl.get",
            ["wwan-ctl", "get", "--json"],
            (stdout, exitCode) => {
                if (exitCode !== 0) {
                    console.warn("wwanCtl: wwan-ctl get exit", exitCode)
                    root.present = false
                    root.connected = false
                    root.modemState = "absent"
                    return
                }
                try {
                    const parsed = JSON.parse(stdout.trim())
                    root.present = parsed.present === true
                    root.modemState = parsed.state || "unknown"
                    root.signalPct = parsed.signal || 0
                    root.tech = parsed.tech || ""
                    root.operator = parsed.operator || ""
                    root.ip = parsed.ip || ""
                    root.connected = parsed.connected === true
                } catch (e) {
                    console.error("wwanCtl: failed to parse JSON:", e, stdout)
                }
            },
            50
        )
    }

    function bringUp() {
        root.busy = true
        Quickshell.execDetached(["wwan-ctl", "connect"])
        postClickRefresh.restart()
    }

    function bringDown() {
        root.busy = true
        Quickshell.execDetached(["wwan-ctl", "disconnect"])
        postClickRefresh.restart()
    }

    function toggle() {
        root.busy = true
        Quickshell.execDetached(["wwan-ctl", "toggle"])
        postClickRefresh.restart()
    }

    // Right-click on the pill toggles the connection without opening the
    // popout. Left-click falls through to the popout (we set popoutContent).
    pillRightClickAction: () => root.toggle()

    // Material Symbols icon. When the link is down we collapse to a single
    // `mobile_off` glyph — the bar pill stops trying to signal "no modem" vs
    // "registered, idle" vs "no data" through three different icons and just
    // says "disconnected". When connected we map signal % → cellular bars so
    // the bar still conveys link quality at a glance.
    function signalIconName() {
        if (!root.connected) return "mobile_off"
        if (root.signalPct >= 80) return "signal_cellular_4_bar"
        if (root.signalPct >= 60) return "signal_cellular_3_bar"
        if (root.signalPct >= 40) return "signal_cellular_2_bar"
        if (root.signalPct >= 20) return "signal_cellular_1_bar"
        return "signal_cellular_0_bar"
    }

    function pillLabel() {
        if (!root.present) return "—"
        if (!root.connected) return "Off"
        if (root.tech.length > 0) return root.tech.toUpperCase()
        return root.signalPct + "%"
    }

    function pillColor() {
        if (!root.present) return Theme.surfaceTextMedium
        if (!root.connected) return Theme.surfaceTextMedium
        return Theme.surfaceText
    }

    Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Re-read after a connect/disconnect — NM takes a couple of seconds to
    // settle. We poll a few times so the UI catches the steady state.
    Timer {
        id: postClickRefresh
        interval: 800
        repeat: true
        triggeredOnStart: false
        property int ticks: 0
        onTriggered: {
            root.refresh()
            ticks += 1
            if (ticks >= 5) {
                ticks = 0
                root.busy = false
                stop()
            }
        }
        function restart() { ticks = 0; running = false; running = true }
    }

    // ==== Bar pill ====

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: root.signalIconName()
                color: root.pillColor()
                size: Theme.iconSize - 6
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.pillLabel()
                color: root.pillColor()
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.signalIconName()
                color: root.pillColor()
                size: Theme.iconSize - 6
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.pillLabel()
                color: root.pillColor()
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ==== Popout panel ====

    popoutContent: Component {
        PopoutComponent {
            id: popout
            showCloseButton: false
            spacing: Theme.spacingM

            // --- Header: signal icon + operator + state ---
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 48
                spacing: Theme.spacingM

                DankIcon {
                    name: root.signalIconName()
                    size: Theme.iconSizeLarge
                    color: root.connected ? Theme.primary : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.iconSizeLarge - 32 - Theme.spacingM * 2

                    StyledText {
                        text: root.present
                            ? (root.operator.length > 0 ? root.operator : "Modem")
                            : "No modem"
                        font.pixelSize: Theme.fontSizeXLarge
                        font.weight: Font.Bold
                        color: root.connected ? Theme.primary : Theme.surfaceText
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    StyledText {
                        text: {
                            if (!root.present) return "ModemManager sees no device"
                            if (root.busy) return "Working…"
                            if (root.connected) return "Connected · " + (root.tech.toUpperCase() || "—")
                            if (root.modemState === "registered") return "Registered, not connected"
                            return root.modemState.charAt(0).toUpperCase() + root.modemState.slice(1)
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeArea.containsMouse ? Theme.errorHover : "transparent"
                    anchors.top: parent.top

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: Theme.iconSize - 4
                        color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            if (popout.closePopout)
                                popout.closePopout()
                        }
                    }
                }
            }

            // --- Stats: signal % + IP address ---
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM
                visible: root.present

                property real cardWidth: (width - spacing) / 2

                StyledRect {
                    width: parent.cardWidth
                    height: 64
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Signal"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        StyledText {
                            text: root.signalPct + "%"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            color: root.signalPct < 20 ? Theme.error : Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                StyledRect {
                    width: parent.cardWidth
                    height: 64
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "IP"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        StyledText {
                            text: {
                                if (!root.ip) return "—"
                                const slash = root.ip.indexOf("/")
                                return slash > 0 ? root.ip.substring(0, slash) : root.ip
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // --- Single contextual action button ---
            // Two states only, so a segmented group is overkill — show the
            // action that's actually available right now. Icon doubles as
            // affirmation (check) vs. negation (close).
            Item {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: actionButton.height
                visible: root.present

                DankButton {
                    id: actionButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.connected ? "Disconnect" : "Connect"
                    iconName: root.connected ? "close" : "check"
                    backgroundColor: Theme.primary
                    textColor: Theme.background
                    onClicked: root.connected ? root.bringDown() : root.bringUp()
                }
            }

            Item {
                width: 1
                height: Theme.spacingL
            }
        }
    }

    popoutWidth: 420
    popoutHeight: 260
}
