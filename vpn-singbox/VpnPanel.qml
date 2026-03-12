import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Injected by PluginService
  property var pluginApi: null

  // SmartPanel sizing hints
  readonly property bool allowAttach: true
  readonly property int contentPreferredWidth: Math.round(360 * Style.uiScaleRatio)
  readonly property int contentPreferredHeight: card.implicitHeight + Style.marginL * 2

  property bool serviceActive: false
  property bool busy: false
  property string lastError: ""

  function refreshServiceState() {
    if (!statusProc.running) {
      statusProc.running = true;
    }
  }

  function setServiceEnabled(enabled) {
    if (busy) {
      return;
    }

    busy = true;
    lastError = "";
    serviceActive = enabled; // optimistic UI

    if (enabled) {
      startProc.running = true;
    } else {
      stopProc.running = true;
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

  Process {
    id: startProc
    command: ["sh", "-lc", "sudo systemctl start sing-box"]
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.busy = false;
      if (exitCode !== 0) {
        root.lastError = stderr.text.trim() || "启动 sing-box 失败";
        ToastService.showError(root.lastError);
      }
      root.refreshServiceState();
    }
  }

  Process {
    id: stopProc
    command: ["sh", "-lc", "sudo systemctl stop sing-box"]
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.busy = false;
      if (exitCode !== 0) {
        root.lastError = stderr.text.trim() || "停止 sing-box 失败";
        ToastService.showError(root.lastError);
      }
      root.refreshServiceState();
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
    id: card
    anchors.fill: parent
    anchors.margins: Style.marginM
    radius: Style.radiusL
    color: Color.mSurface
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NIcon {
          icon: root.serviceActive ? "shield-lock" : "shield"
          color: root.serviceActive ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeL
        }

        NText {
          Layout.fillWidth: true
          text: "Sing-box VPN"
          color: Color.mOnSurface
          pointSize: Style.fontSizeM
          font.weight: Font.Medium
        }

        NIconButton {
          icon: "refresh"
          tooltipText: "刷新状态"
          enabled: !root.busy
          onClicked: root.refreshServiceState()
        }
      }

      NToggle {
        label: "VPN 开关"
        description: root.serviceActive ? "当前状态：运行中" : "当前状态：已停止"
        icon: root.serviceActive ? "shield-lock" : "shield-off"
        checked: root.serviceActive
        enabled: !root.busy
        onToggled: checked => root.setServiceEnabled(checked)
      }

      RowLayout {
        visible: root.busy
        Layout.fillWidth: true
        spacing: Style.marginS

        NBusyIndicator {
          Layout.preferredWidth: Style.baseWidgetSize * 0.8
          Layout.preferredHeight: Style.baseWidgetSize * 0.8
        }

        NText {
          text: "正在执行 systemctl 命令..."
          color: Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
        }
      }

      NText {
        visible: root.lastError.length > 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: root.lastError
        color: Color.mError
        pointSize: Style.fontSizeS
      }
    }
  }
}
