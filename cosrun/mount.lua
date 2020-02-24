local mountfile = [[local attachments = ##ATTACHMENTS##
if not mounter then
  error("Not running in CraftOS-PC", 2)
end
for inside, outside in pairs(attachments) do
  -- readonly mode not supported from cosrun
  if inside ~= "/" then mounter.mount(inside, outside, false) end
end
]]
local insertAttachments
insertAttachments = function(txt, tbl)
  local y = txt:gsub("##ATTACHMENTS##", function()
    local final = "{"
    for inside, outside in pairs(tbl) do
      final = final .. "['" .. tostring(inside) .. "']='" .. tostring(outside) .. "',"
    end
    return final .. "}"
  end)
  return y
end
local createMountfile
createMountfile = function(env, tbl)
  do
    local _with_0 = io.open(".cosrun/" .. tostring(env) .. "/mount.lua", "w")
    _with_0:write(insertAttachments(mountfile, tbl))
    _with_0:close()
    return _with_0
  end
end
return {
  insertAttachments = insertAttachments,
  mountfile = mountfile,
  createMountfile = createMountfile
}
