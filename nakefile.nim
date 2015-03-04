import nake

const
  NimName = "src/logger.nim"
  ExeName = "--out:../logger"

task "debug", "Build for debugging":
  shell(nimExe, "c", "-d:debug", ExeName, NimName)

task "release", "Build for release":
  shell(nimExe, "c", "-d:release", ExeName, NimName)