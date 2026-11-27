import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "shyamenk.robot"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩"
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Style.bar.iconFont
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-menu toggle")
    }
  }
}
