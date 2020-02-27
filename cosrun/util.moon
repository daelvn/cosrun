-- cosrun.util
-- Util functions for COSRun
-- By daelvn
fs   = require "filekit"
ansi = require "ansikit.style"

-- aliases
color = ansi.colorize

-- print functions
fatarrow = (txt) ->
  print color "%{bold blue}=>%{notBold white} #{txt}"

arrow = (txt) ->
  print color "%{bold green}->%{notBold white} #{txt}"

bangs = (txt) ->
  print color "%{bold red}!!%{notBold white} #{txt}"

header = (txt) ->
  print color "%{bold blue}#{txt}"

-- fs functions
absolutePath = (path) ->
  return path if "/" == path\sub 1, 1
  pwd = fs.currentDir!
  return fs.combine pwd, path

toWSLPath = (path, prefix) -> prefix..path\gsub "/", "\\"

safeMakeDir = (dir) -> unless fs.exists dir
  fs.makeDir dir

safeRemove = (path) -> if fs.exists path
  if fs.isDir path
    nodes = fs.list path
    if #nodes < 1
      fs.delete path
    else
      for node in *nodes
        continue if (node == ".") or (node == "..")
        safeRemove fs.combine path, node
      fs.delete path
  elseif fs.isFile path
    fs.delete path

safeReplaceDir = (dir) ->
  safeRemove  dir
  safeMakeDir dir

safeMove = (old, new) -> if fs.exists old
  fs.move old, new

safeReadAll = (path) -> with fs.safeOpen path
  return false if .error
  content = \read "*a"
  \close!
  return content

safeWriteAll = (path, txt) -> with fs.safeOpen path, "w"
  return false if .error
  \write txt
  \close!
  return true

safeCopy = (fr, to) ->
  --safeRemove to
  if fs.isDir fr
    safeMakeDir to
    for node in *fs.list fr
      continue if (node == ".") or (node == "..")
      safeCopy (fs.combine fr, node), (fs.combine to, node)
  elseif fs.isFile fr
    fs.copy fr, to
  else error "unknown type for path #{fr}"
  
{
  :header, :fatarrow, :arrow, :bangs
  :safeMakeDir, :safeRemove, :safeReplaceDir
  :safeMove, :safeReadAll, :safeWriteAll
  :absolutePath, :toWSLPath, :symlink
  :safeCopy
}