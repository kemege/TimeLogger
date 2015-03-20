import nake

const
  exeName = @["logger", "server"]

task "debug", "Build everything for debugging":
  for exe in exeName:
    when defined(windows):
      var extra = "--passL:resources/" & exe & ".res"
    shell(nimExe, "c", "-d:debug", "--out:../" & exe, extra, "src/" & exe)

task "release", "Build everything for release":
  for exe in exeName:
    when defined(windows):
      var extra = "--passL:resources/" & exe & ".res"
    shell(nimExe, "c", "-d:release", "--out:../" & exe, extra, "src/" & exe)

task "logger", "Build logger for debugging":
  let exe = "logger"
  when defined(windows):
    var extra = "--passL:resources/" & exe & ".res"
  shell(nimExe, "c", "-d:debug", "--threads:on", "--out:../" & exe, extra, "src/" & exe)

task "server", "Build server for debugging":
  let exe = "server"
  when defined(windows):
    var extra = "--passL:resources/" & exe & ".res"
  shell(nimExe, "c", "-d:debug", "--out:../" & exe, extra, "src/" & exe)

task defaultTask, "lists all tasks":
  listTasks()