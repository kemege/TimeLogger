import nake

const
  exeName = @["logger"]

task "debug", "Build for debugging":
  for exe in exeName:
    shell(nimExe, "c", "-d:debug", "--out:../" & exe, "src/" & exe)

task "release", "Build for release":
  for exe in exeName:
    shell(nimExe, "c", "-d:release", "--out:../" & exe, "src/" & exe)