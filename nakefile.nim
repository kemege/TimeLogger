import nake

const
  exeName = @["logger", "server"]

task "debug", "Build everything for debugging":
  for exe in exeName:
    shell(nimExe, "c", "-d:debug", "--out:../" & exe, "src/" & exe)

task "release", "Build everything for release":
  for exe in exeName:
    shell(nimExe, "c", "-d:release", "--out:../" & exe, "src/" & exe)

task "logger", "Build logger for debugging":
  let exe = "logger"
  shell(nimExe, "c", "-d:debug", "--threads:on", "--out:../" & exe, "src/" & exe)

task "server", "Build server for debugging":
  let exe = "server"
  shell(nimExe, "c", "-d:debug", "--out:../" & exe, "src/" & exe)

task defaultTask, "lists all tasks":
  listTasks()