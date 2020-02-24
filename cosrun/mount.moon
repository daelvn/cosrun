mountfile = [[
local attachments = ##ATTACHMENTS##
if not mounter then
  error("Not running in CraftOS-PC", 2)
end
for inside, outside in pairs(attachments) do
  -- readonly mode not supported from cosrun
  mounter.mount(inside, outside, false)
end
]]

insertAttachments = (txt, tbl) ->
  y = txt\gsub "##ATTACHMENTS##", ->
    final = "{"
    for inside, outside in pairs tbl
      final ..= "['#{inside}']='#{outside}',"
    final .. "}"
  return y

createMountfile = (env, tbl) ->
  with io.open ".cosrun/#{env}/mount.lua", "w"
    \write insertAttachments mountfile, tbl
    \close! 

{
  :insertAttachments, :mountfile
  :createMountfile
}