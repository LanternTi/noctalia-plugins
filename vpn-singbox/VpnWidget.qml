import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  // Plugin API (injected by PluginService)
  property var pluginApi: null

  // Required bar widget properties
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Per-screen bar properties
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // VPN service state
  property bool serviceActive: false

  // Support vertical bars
  readonly property real contentWidth: isBarVertical ? capsuleHeight : content.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: isBarVertical ? content.implicitHeight + Style.marginM * 2 : capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function refreshServiceState() {
    if (!statusProc.running) {
      statusProc.running = true;
    }
  }

  Process {
    id: statusProc
    command: ["sh", "-lc", "systemctl is-active sing-box"]
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      const output = stdout.text.trim();
      root.serviceActive = (exitCode === 0 && output === "active");
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: root.refreshServiceState()
  }

  Component.onCompleted: refreshServiceState()

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

    Item {
      id: content
      anchors.centerIn: parent
      implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth
      implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight

      RowLayout {
        id: rowLayout
        visible: !root.isBarVertical
        spacing: Style.marginS

        NIcon {
          icon: root.serviceActive ? "shield-lock" : "shield"
          color: root.serviceActive ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: root.barFontSize
        }

        NText {
          text: root.serviceActive ? "VPN On" : "VPN Off"
          color: Color.mOnSurface
          pointSize: root.barFontSize
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        id: colLayout
        visible: root.isBarVertical
        spacing: Style.marginS

        NIcon {
          icon: root.serviceActive ? "shield-lock" : "shield"
          color: root.serviceActive ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: root.barFontSize
        }

        NText {
          text: root.serviceActive ? "On" : "Off"
          color: Color.mOnSurface
          pointSize: root.barFontSize
          font.weight: Font.Medium
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      root.refreshServiceState();
      if (root.pluginApi) {
        root.pluginApi.openPanel(root.screen, root);
      }
    }
  }
}
