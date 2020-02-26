local yaml = require("lyaml")
local util = require("cosrun.util")
local mount = require("cosrun.mount")
local VERSION = "0.2.1"
local purge
purge = function(t)
  local unwanted = {
    "environment",
    "new",
    "delete",
    "rename",
    "run",
    "attach",
    "see",
    "add",
    "image",
    "pack"
  }
  for _index_0 = 1, #unwanted do
    local index = unwanted[_index_0]
    t[index] = nil
  end
  return t
end
local args
do
  local _with_0 = (require("argparse"))()
  _with_0:name("cosrun")
  _with_0:description("Make running projects with CraftOS-PC 2 easier")
  _with_0:epilog("https://github.com/daelvn/cosrun")
  _with_0:command_target("action")
  do
    local _with_1 = _with_0:flag("-v --version")
    _with_1:description("Prints the COSRun version")
    _with_1:action(function()
      print("cosrun " .. tostring(VERSION))
      return os.exit()
    end)
  end
  do
    local _with_1 = _with_0:option("-c --config")
    _with_1:description("Configuration file for COSRun")
    _with_1:target("config")
  end
  do
    local _with_1 = _with_0:command("environment env e")
    _with_1:description("Manage COSRun environments")
    _with_1:command_target("env_action")
    do
      local _with_2 = _with_1:command("new n")
      _with_2:description("Creates a new environment")
      _with_2:argument("name")
    end
    do
      local _with_2 = _with_1:command("delete del d")
      _with_2:description("Deletes an environment")
      _with_2:argument("name")
    end
    do
      local _with_2 = _with_1:command("rename ren r")
      _with_2:description("Renames an environment")
      _with_2:argument("name")
      _with_2:argument("newname")
    end
    do
      local _with_2 = _with_1:command("set s")
      _with_2:description("Sets the environment to use")
      _with_2:argument("name")
    end
  end
  do
    local _with_1 = _with_0:command("run r")
    _with_1:description("Runs an environment")
    _with_1:argument("env")
    do
      local _with_2 = _with_1:option("-i --id")
      _with_2:target("id")
      _with_2:default(0)
    end
  end
  do
    local _with_1 = _with_0:command("clean c")
    _with_1:description("Cleans files in an environment")
    do
      local _with_2 = _with_1:argument("id")
      _with_2:description("ID to clean")
      _with_2:args("?")
    end
    do
      local _with_2 = _with_1:flag("-a --all")
      _with_2:description("cleans all environments")
    end
  end
  do
    local _with_1 = _with_0:command("attach a")
    _with_1:description("Attaches folders to the environment")
    _with_1:command_target("attach_action")
    do
      local _with_2 = _with_1:command("regenerate regen rg")
      _with_2:description("Regenerates mount.lua")
    end
    do
      local _with_2 = _with_1:command("see s")
      _with_2:description("See attached folders")
    end
    do
      local _with_2 = _with_1:command("add a")
      _with_2:description("Attach a new folder")
      do
        local _with_3 = _with_2:flag("--root")
        _with_3:description("Make this folder the root of the computer")
      end
      do
        local _with_3 = _with_2:flag("--rom")
        _with_3:description("Make this folder be mounted as /root")
      end
      do
        local _with_3 = _with_2:flag("--bios")
        _with_3:description("Make this file be used as bios.lua")
      end
      do
        local _with_3 = _with_2:argument("path")
        _with_3:description("Folder to attach")
      end
      do
        local _with_3 = _with_2:argument("target")
        _with_3:description("Path inside the target computer to mount")
        _with_3:args("?")
      end
    end
    do
      local _with_2 = _with_1:command("remove rm r")
      _with_2:description("Removes an attachment")
      do
        local _with_3 = _with_2:flag("--root")
        _with_3:description("Make this folder the root of the computer")
      end
      do
        local _with_3 = _with_2:argument("target")
        _with_3:description("Path inside the target computer")
        _with_3:args("?")
      end
    end
  end
  do
    local _with_1 = _with_0:command("image img i")
    _with_1:description("Packs or runs COSRun images.")
    _with_1:command_target("image_action")
    do
      local _with_2 = _with_1:command("pack p")
      _with_2:description("Packs an image")
      do
        local _with_3 = _with_2:argument("env")
        _with_3:description("Environment to pack")
      end
      do
        local _with_3 = _with_2:argument("output")
        _with_3:description("Output file (YAML format)")
      end
    end
    do
      local _with_2 = _with_1:command("unpack u")
      _with_2:description("Unpacks an image")
      do
        local _with_3 = _with_2:argument("img")
        _with_3:description("Image to run")
      end
    end
  end
  args = purge(_with_0:parse())
end
util.safeMakeDir(".cosrun")
local config = (yaml.load((util.safeReadAll((args.config or "cosrun.yml"))) or "")) or { }
config.flags = config.flags or ""
local loadAttachments
loadAttachments = function(env)
  return (yaml.load((util.safeReadAll(".cosrun/" .. tostring(env) .. "/attachments.yml")) or "")) or { }
end
util.header("cosrun " .. tostring(VERSION))
local self = args
local errorEnv
errorEnv = function()
  if not (config.env) then
    util.bangs("Environment is not set. Do `cosrun env set <name>`")
    return os.exit()
  end
end
local packImage
packImage = function()
  util.fatarrow("Generating image for " .. tostring(self.env) .. " at " .. tostring(self.output))
  local image = { }
  local atl = loadAttachments(self.env)
  image.attachments = atl
  image.name = self.env
  image.mountfile = util.safeReadAll(".cosrun/" .. tostring(self.env) .. "/mount.lua")
  return util.safeWriteAll(self.output, yaml.dump({
    image
  }))
end
local unpackImage
unpackImage = function()
  util.fatarrow("Unpacking image: %{yellow}" .. tostring(self.img))
  local image = (yaml.load((util.safeReadAll(self.img)) or "")) or { }
  util.arrow("Image name: %{green}" .. tostring(image.name))
  util.safeReplaceDir(".cosrun/" .. image.name)
  for inside, outside in pairs(image.attachments) do
    util.arrow("Attachment: %{green}" .. tostring(inside) .. "%{white} -> %{yellow}" .. tostring(outside))
  end
  util.safeWriteAll(".cosrun/" .. tostring(image.name) .. "/attachments.yml", yaml.dump({
    image.attachments
  }))
  return util.safeWriteAll(".cosrun/" .. tostring(image.name) .. "/mount.lua", image.mountfile)
end
local newEnv
newEnv = function()
  util.fatarrow("Creating new environment: %{green}" .. tostring(self.name))
  return util.safeReplaceDir(".cosrun/" .. self.name)
end
local deleteEnv
deleteEnv = function()
  util.fatarrow("Deleting environment: %{red}" .. tostring(self.name))
  return util.safeRemove(".cosrun/" .. self.name)
end
local renameEnv
renameEnv = function()
  util.fatarrow("Renaming environment: %{red}" .. tostring(self.name) .. "%{white} -> %{green}" .. tostring(self.newname))
  return util.safeMove(".cosrun/" .. self.name, ".cosrun/" .. self.newname)
end
local setEnv
setEnv = function()
  util.fatarrow("Using environment: %{yellow}" .. tostring(self.name))
  config.env = self.name
end
local clean
clean = function(env, prefix)
  errorEnv()
  if (not self.all) and (not prefix) then
    util.bangs("ID needed to clear files")
    os.exit()
  end
  util.fatarrow("Clearing all files in .cosrun/" .. tostring(env) .. "/computer/" .. tostring(prefix))
  util.safeRemove(".cosrun/" .. tostring(env) .. "/computer/" .. tostring(prefix))
  return util.safeMakeDir(".cosrun/" .. tostring(env) .. "/computer/" .. tostring(prefix))
end
local regenMount
regenMount = function()
  errorEnv()
  util.arrow("Creating mount.lua...")
  return mount.createMountfile(config.env, loadAttachments(config.env))
end
local seeAttaches
seeAttaches = function()
  util.fatarrow("Showing attachments:")
  for target, path in pairs(loadAttachments(config.env)) do
    util.arrow("%{bold}" .. tostring(target) .. ": %{notBold italic}" .. tostring(path))
  end
end
local addAttach
addAttach = function()
  local attachments = loadAttachments(config.env)
  errorEnv()
  if self.root then
    self.target = "/"
  end
  if self.rom then
    self.target = "/rom"
  end
  if self.bios then
    self.target = "bios.lua"
  end
  util.fatarrow("Attaching %{yellow}" .. tostring(self.path) .. "%{white} as %{green}" .. tostring(self.target))
  attachments[self.target] = self.path
  util.safeWriteAll(".cosrun/" .. tostring(config.env) .. "/attachments.yml", yaml.dump({
    attachments
  }))
  util.arrow("Creating mount.lua...")
  return mount.createMountfile(config.env, attachments)
end
local removeAttach
removeAttach = function()
  local attachments = loadAttachments(config.env)
  errorEnv()
  if self.root then
    self.target = "/"
  end
  if self.rom then
    self.target = "/rom"
  end
  if self.bios then
    self.target = "bios.lua"
  end
  util.fatarrow("Removing attachment for " .. tostring(self.target))
  attachments[self.target] = nil
  util.safeWriteAll(".cosrun/" .. tostring(config.env) .. "/attachments.yml", yaml.dump({
    attachments
  }))
  util.arrow("Creating mount.lua...")
  return mount.createMountfile(config.env, attachments)
end
local subrun
subrun = function(wsl)
  local attachments = loadAttachments(config.env)
  local at = ".cosrun/" .. tostring(self.env)
  local root = attachments['/']
  util.arrow("Copying root to ID " .. tostring(self.id))
  util.safeMakeDir(root)
  util.safeMakeDir(tostring(at) .. "/computer")
  util.safeMakeDir(tostring(at) .. "/computer/" .. tostring(self.id))
  util.safeCopy(root, tostring(at) .. "/computer/" .. tostring(self.id))
  local rom, bios
  if attachments["/rom"] then
    rom = attachments["/rom"]
    util.arrow("Copying /rom to ID " .. tostring(self.id))
    util.safeMakeDir(tostring(at) .. "/internal/")
    util.safeMakeDir(tostring(at) .. "/internal/rom/")
    util.safeCopy(rom, tostring(at) .. "/internal/rom/")
  end
  if attachments["bios.lua"] then
    bios = attachments["bios.lua"]
    util.arrow("Copying bios.lua to ID " .. tostring(self.id))
    util.safeMakeDir(tostring(at) .. "/internal/")
    util.safeCopy(bios, tostring(at) .. "/internal/bios.lua")
  end
  util.arrow("Running...")
  local command = "\"" .. tostring(config.executable) .. "\"" .. (wsl and " --directory '" .. tostring(util.toWSLPath((util.absolutePath(at)), config.wsl.prefix)) .. "'" or " --directory '" .. tostring(at) .. "'") .. " --script .cosrun/" .. tostring(self.env) .. "/mount.lua" .. " --id " .. tostring(self.id) .. ((rom or bios) and " --rom .cosrun/" .. tostring(self.env) .. "/internal/" or "") .. " " .. tostring(config.flags)
  os.execute(command)
  util.arrow("Copying ID " .. tostring(self.id) .. " to root")
  return util.safeCopy(tostring(at) .. "/computer/" .. tostring(self.id), root)
end
local run
run = function()
  if not (config.executable) then
    util.bangs("Missing path for CraftOS-PC executable")
    os.exit()
  end
  util.arrow("Setting environment to " .. tostring(self.env))
  config.env = self.env
  clean(self.env, self.id)
  local attachments = loadAttachments(config.env)
  if not (attachments["/"]) then
    util.bangs("No / attachment. Set with `cosrun attach add <folder> --root`")
    os.exit()
  end
  util.fatarrow("Running CraftOS-PC with environment %{green}" .. tostring(self.env))
  return subrun(config.wsl.use)
end
local _exp_0 = self.action
if "image" == _exp_0 then
  local _exp_1 = self.image_action
  if "pack" == _exp_1 then
    packImage()
  elseif "unpack" == _exp_1 then
    unpackImage()
  end
elseif "environment" == _exp_0 then
  local _exp_1 = self.env_action
  if "new" == _exp_1 then
    newEnv()
  elseif "delete" == _exp_1 then
    deleteEnv()
  elseif "rename" == _exp_1 then
    renameEnv()
  elseif "set" == _exp_1 then
    setEnv()
  elseif "clean" == _exp_1 then
    clean(config.env, self.id)
  end
elseif "attach" == _exp_0 then
  local _exp_1 = self.attach_action
  if "regenerate" == _exp_1 then
    regenMount()
  elseif "see" == _exp_1 then
    seeAttaches()
  elseif "add" == _exp_1 then
    addAttach()
  elseif "remove" == _exp_1 then
    removeAttach()
  end
elseif "run" == _exp_0 then
  run()
end
return util.safeWriteAll("cosrun.yml", yaml.dump({
  config
}))
