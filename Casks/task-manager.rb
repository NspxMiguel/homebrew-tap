cask "task-manager" do
  version "1.0.0"
  sha256 "147a220200ec625ae14637610eb37f303a1438f49171f1989d7d2c39441a35c7"

  url "https://github.com/spxmiguel/mac-task-manager/releases/download/v#{version}/TaskManager-#{version}-macos.zip"
  name "Task Manager"
  desc "Gerenciador de tarefas nativo para macOS, estilo Windows 11"
  homepage "https://github.com/spxmiguel/mac-task-manager"

  depends_on macos: :ventura

  app "TaskManager.app"

  zap trash: [
    "~/Library/Preferences/com.miguel.taskmanager.plist",
  ]
end
