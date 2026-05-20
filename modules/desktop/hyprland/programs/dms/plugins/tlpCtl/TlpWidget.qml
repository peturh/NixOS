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
    property string profile: "auto"
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

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Battery & Power"
            detailsText: BatteryService.batteryAvailable
                ? BatteryService.batteryStatus + " · " + BatteryService.batteryLevel + "%"
                : "No battery detected"
            showCloseButton: true
            spacing: Theme.spacingM

            // --- Battery stats: two side-by-side cards ---
            //
            // Each card is a StyledRect with a primary-colored label
            // (e.g. "Health") above a bold surfaceText value (e.g. "90%").
            // Time-remaining is intentionally omitted — the popout is for
            // quick status + profile swap, not a full diagnostic panel.
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                property real cardWidth: (width - spacing) / 2
                property int cardHeight: 72

                StyledRect {
                    width: parent.cardWidth
                    height: parent.cardHeight
                    color: Theme.surfaceVariant
                    radius: Theme.cornerRadius

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Health"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        StyledText {
                            text: BatteryService.batteryHealth
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                StyledRect {
                    width: parent.cardWidth
                    height: parent.cardHeight
                    color: Theme.surfaceVariant
                    radius: Theme.cornerRadius

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Capacity"
                            font.pixelSize: Theme.fontSizeSmall
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

            // --- Power-profile buttons ---
            //
            // Selection cue mirrors the stock DMS battery widget: a leading
            // "check" Material icon + a primary-tinted background on the
            // active button. Unselected buttons use surfaceVariant (Material
            // 3's neutral "filled but not accented" surface) — *not*
            // Theme.buttonBg, which the upstream Theme.qml at this rev
            // defaults to `primary` (matugen ends up making that red on
            // wallpaper-derived palettes, so unselected buttons looked the
            // same as the active one).
            //
            // Text colors:
            //   • Unselected → Theme.surfaceText (follows light/dark mode,
            //     so it reads correctly on the gray surfaceVariant).
            //   • Selected   → literal white. We tried Theme.onPrimary
            //     (matugen computed it as black on this red palette) and
            //     Theme.surfaceText (flips to black in light mode); both
            //     gave dark-on-red, which is what we're trying to avoid.
            //     A fixed white is the only color guaranteed to read on
            //     any wallpaper-derived primary in either mode.
            //
            // `auto` profile is intentionally not surfaced; users can still
            // hit `tlp-ctl set auto` from a shell if they want it.
            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                property real btnWidth: (width - spacing * 2) / 3

                DankButton {
                    width: parent.btnWidth
                    text: "Power Save"
                    iconName: root.profile === "low" ? "check" : ""
                    backgroundColor: root.profile === "low" ? Theme.primary : Theme.surfaceVariant
                    textColor: root.profile === "low" ? "#ffffff" : Theme.surfaceText
                    onClicked: root.setProfile("low")
                }
                DankButton {
                    width: parent.btnWidth
                    text: "Balanced"
                    iconName: root.profile === "medium" ? "check" : ""
                    backgroundColor: root.profile === "medium" ? Theme.primary : Theme.surfaceVariant
                    textColor: root.profile === "medium" ? "#ffffff" : Theme.surfaceText
                    onClicked: root.setProfile("medium")
                }
                DankButton {
                    width: parent.btnWidth
                    text: "Performance"
                    iconName: root.profile === "performance" ? "check" : ""
                    backgroundColor: root.profile === "performance" ? Theme.primary : Theme.surfaceVariant
                    textColor: root.profile === "performance" ? "#ffffff" : Theme.surfaceText
                    onClicked: root.setProfile("performance")
                }
            }

            // Bottom padding so the buttons aren't flush with the popout
            // edge. PopoutComponent doesn't add its own.
            Item {
                width: 1
                height: Theme.spacingL
            }
        }
    }

    popoutWidth: 420
    popoutHeight: 360
}
