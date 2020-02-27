local fs = require("filekit")
local ansi = require("ansikit.style")
local color = ansi.colorize
local fatarrow
fatarrow = function(txt)
  return print(color("%{bold blue}=>%{notBold white} " .. tostring(txt)))
end
local arrow
arrow = function(txt)
  return print(color("%{bold green}->%{notBold white} " .. tostring(txt)))
end
local bangs
bangs = function(txt)
  return print(color("%{bold red}!!%{notBold white} " .. tostring(txt)))
end
local header
header = function(txt)
  return print(color("%{bold blue}" .. tostring(txt)))
end
local absolutePath
absolutePath = function(path)
  if "/" == path:sub(1, 1) then
    return path
  end
  local pwd = fs.currentDir()
  return fs.combine(pwd, path)
end
local toWSLPath
toWSLPath = function(path, prefix)
  return prefix .. path:gsub("/", "\\")
end
local safeMakeDir
safeMakeDir = function(dir)
  if not (fs.exists(dir)) then
    return fs.makeDir(dir)
  end
end
local safeRemove
safeRemove = function(path)
  if fs.exists(path) then
    if fs.isDir(path) then
      local nodes = fs.list(path)
      if #nodes < 1 then
        return fs.delete(path)
      else
        for _index_0 = 1, #nodes do
          local _continue_0 = false
          repeat
            local node = nodes[_index_0]
            if (node == ".") or (node == "..") then
              _continue_0 = true
              break
            end
            safeRemove(fs.combine(path, node))
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        return fs.delete(path)
      end
    elseif fs.isFile(path) then
      return fs.delete(path)
    end
  end
end
local safeReplaceDir
safeReplaceDir = function(dir)
  safeRemove(dir)
  return safeMakeDir(dir)
end
local safeMove
safeMove = function(old, new)
  if fs.exists(old) then
    return fs.move(old, new)
  end
end
local safeReadAll
safeReadAll = function(path)
  do
    local _with_0 = fs.safeOpen(path)
    if _with_0.error then
      return false
    end
    local content = _with_0:read("*a")
    _with_0:close()
    return content
  end
end
local safeWriteAll
safeWriteAll = function(path, txt)
  do
    local _with_0 = fs.safeOpen(path, "w")
    if _with_0.error then
      return false
    end
    _with_0:write(txt)
    _with_0:close()
    return true
  end
end
local safeCopy
safeCopy = function(fr, to)
  if fs.isDir(fr) then
    safeMakeDir(to)
    local _list_0 = fs.list(fr)
    for _index_0 = 1, #_list_0 do
      local _continue_0 = false
      repeat
        local node = _list_0[_index_0]
        if (node == ".") or (node == "..") then
          _continue_0 = true
          break
        end
        safeCopy((fs.combine(fr, node)), (fs.combine(to, node)))
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  elseif fs.isFile(fr) then
    return fs.copy(fr, to)
  else
    return error("unknown type for path " .. tostring(fr))
  end
end
return {
  header = header,
  fatarrow = fatarrow,
  arrow = arrow,
  bangs = bangs,
  safeMakeDir = safeMakeDir,
  safeRemove = safeRemove,
  safeReplaceDir = safeReplaceDir,
  safeMove = safeMove,
  safeReadAll = safeReadAll,
  safeWriteAll = safeWriteAll,
  absolutePath = absolutePath,
  toWSLPath = toWSLPath,
  symlink = symlink,
  safeCopy = safeCopy
}
