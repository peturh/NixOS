import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "tlp-ctl"

    // ==== TLP profile state ====
    //
    // Mirrors tlp-ctl get --json output:
    //   profile  ∈ low | medium | performance | auto
    //   handling ∈ manual | auto   (whether the state file is currently
    //                              authoritative or we fell back to the
    //                              AC-state default)
    //
    // The bar pill itself no longer shows the profile (the popout owns
    // that — three explicit buttons make the current choice obvious).
    // We still keep these properties around so the active button can
    // be highlighted.
    // Seed with `medium` so the popout's segmented selector has a button
    // highlighted from the moment it opens, even before the first
    // refreshProfile() call returns. tlp-ctl get auto-initializes the state
    // file on missing/stale reads, so this seed is overwritten quickly with
    // the real AC-state default (medium on AC, low on battery).
    property string profile: "medium"
    property string handling: "auto"
    property int pollIntervalMs: 5000

    function refreshProfile() {
        Proc.runCommand(
            "tlpCtl.get",
            ["tlp-ctl", "get", "--json"],
            (stdout, exitCode) => {
                if (exitCode !== 0) {
                    console.warn("tlpCtl: tlp-ctl get --json exit", exitCode)
                    return
                }
                try {
                    const parsed = JSON.parse(stdout.trim())
                    root.profile = parsed.text || parsed.alt || "auto"
                    const classes = parsed.class || []
                    root.handling = classes.length > 1 ? classes[1] : "auto"
                } catch (e) {
                    console.error("tlpCtl: failed to parse tlp-ctl JSON:", e, stdout)
                }
            },
            50
        )
    }

    function setProfile(p) {
        // tlp-ctl set itself shells out to pkexec, but the polkit rule in
        // modules/programs/misc/tlp/default.nix grants the `power` group a
        // password-less yes — so this is fire-and-forget from QML's side.
        Quickshell.execDetached(["tlp-ctl", "set", p])
        postClickRefresh.restart()
    }

    function cycleProfile() {
        Quickshell.execDetached(["tlp-ctl", "cycle"])
        postClickRefresh.restart()
    }

    // Right-click on the pill cycles low → medium → performance → low.
    // Left-click is left to its default (open the popout, since we set
    // popoutContent). The PluginComponent base wires both up.
    pillRightClickAction: () => root.cycleProfile()

    // Emoji shown on the bar pill next to the battery readout, so the
    // current power profile is visible at a glance without opening the
    // popout. Buttons in the popout deliberately do NOT carry these — they
    // use a leading check icon (Material) to indicate selection instead,
    // matching the stock battery widget's pattern.
    function emojiFor(p) {
        switch (p) {
        case "low":
            return "🍃";
        case "medium":
            return "⚖️";
        case "performance":
            return "⚡";
        default:
            return "";
        }
    }

    Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshProfile()
    }

    // Re-read shortly after a `set` so the active-button highlight follows
    // the new state. tlp itself takes a beat to apply via pkexec.
    Timer {
        id: postClickRefresh
        interval: 400
        repeat: false
        onTriggered: root.refreshProfile()
    }

    // ==== Bar pill ====
    //
    // Shows battery state, not power profile. BatteryService.getBatteryIcon()
    // already encodes charging/discharging + level into a Material icon name
    // (battery_charging_full, battery_full, battery_3_bar, …), so we just
    // pass it through.

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: BatteryService.batteryAvailable ? BatteryService.getBatteryIcon() : "bolt"
                color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
                size: Theme.iconSize - 6
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: BatteryService.batteryAvailable ? BatteryService.batteryLevel + "%" : "—"
                color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.emojiFor(root.profile)
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                visible: text.length > 0
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: BatteryService.batteryAvailable ? BatteryService.getBatteryIcon() : "bolt"
                color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
                size: Theme.iconSize - 6
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: BatteryService.batteryAvailable ? BatteryService.batteryLevel + "%" : "—"
                color: BatteryService.isLowBattery && !BatteryService.isCharging ? Theme.error : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.emojiFor(root.profile)
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text.length > 0
            }
        }
    }

    // ==== Popout panel ====
    //
    // PopoutComponent is itself a Column (see quickshell/Modules/Plugins/
    // PopoutComponent.qml — `Column { id: root; ... }`), so children stack
    // vertically with `spacing` honored. No ColumnLayout needed.

    // Mirror the stock DMS BatteryPopout look: big icon + percentage header,
    // nestedSurface stat cards, and a connected DankButtonGroup for profile
    // selection. We leave PopoutComponent.headerText empty and roll our own
    // header so the layout matches the stock widget exactly (icon + bold
    // percentage + status text + close button), instead of the bold title
    // + subtitle that PopoutComponent renders by default.

    popoutContent: Component {
        PopoutComponent {
            id: popout

            showCloseButton: false
            spacing: Theme.spacingM

            property var profiles: ["low", "medium", "performance"]
            property var profileLabels: ["Power Save", "Balanced", "Performance"]

            // --- Custom header row (icon + percentage + status + close) ---
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 48
                spacing: Theme.spacingM

                DankIcon {
                    name: BatteryService.batteryAvailable ? BatteryService.getBatteryIcon() : "power"
                    size: Theme.iconSizeLarge
                    color: {
                        if (BatteryService.isLowBattery && !BatteryService.isCharging)
                            return Theme.error
                        if (BatteryService.isCharging || BatteryService.isPluggedIn)
                            return Theme.primary
                        return Theme.surfaceText
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.iconSizeLarge - 32 - Theme.spacingM * 2

                    Row {
                        spacing: Theme.spacingS

                        StyledText {
                            text: BatteryService.batteryAvailable ? BatteryService.batteryLevel + "%" : "Power"
                            font.pixelSize: Theme.fontSizeXLarge
                            font.weight: Font.Bold
                            color: {
                                if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                    return Theme.error
                                if (BatteryService.isCharging)
                                    return Theme.primary
                                return Theme.surfaceText
                            }
                        }

                        StyledText {
                            text: BatteryService.batteryStatus
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: {
                                if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                    return Theme.error
                                if (BatteryService.isCharging)
                                    return Theme.primary
                                return Theme.surfaceText
                            }
                            visible: BatteryService.batteryAvailable
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: {
                            if (!BatteryService.batteryAvailable)
                                return ""
                            const time = BatteryService.formatTimeRemaining()
                            if (time !== "Unknown") {
                                return BatteryService.isCharging ? "Time until full: " + time : "Time remaining: " + time
                            }
                            return ""
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                        visible: text.length > 0
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

            // --- Battery stats: two side-by-side cards ---
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM
                visible: BatteryService.batteryAvailable

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
                            text: "Health"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        StyledText {
                            text: BatteryService.batteryHealth
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            color: {
                                if (BatteryService.batteryHealth === "N/A")
                                    return Theme.surfaceText
                                const healthNum = parseInt(BatteryService.batteryHealth)
                                return healthNum < 80 ? Theme.error : Theme.surfaceText
                            }
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
                            text: "Capacity"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        StyledText {
                            text: BatteryService.batteryAvailable
                                ? BatteryService.batteryEnergy.toFixed(1) + " Wh"
                                : "—"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // --- Power-profile buttons: connected segmented group ---
            // Matches the stock DankBar BatteryPopout, which uses
            // DankButtonGroup for the profile selector. `auto` is
            // intentionally not surfaced; `tlp-ctl set auto` from a shell
            // still works.
            Item {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: profileButtonGroup.height * profileButtonGroup.scale

                DankButtonGroup {
                    id: profileButtonGroup
                    scale: Math.min(1, parent.width / implicitWidth)
                    transformOrigin: Item.Center
                    anchors.horizontalCenter: parent.horizontalCenter
                    model: popout.profileLabels
                    currentIndex: popout.profiles.indexOf(root.profile)
                    selectionMode: "single"
                    onSelectionChanged: (index, selected) => {
                        if (!selected)
                            return
                        root.setProfile(popout.profiles[index])
                    }
                }
            }

            Item {
                width: 1
                height: Theme.spacingL
            }
        }
    }

    popoutWidth: 420
    popoutHeight: 280
}
