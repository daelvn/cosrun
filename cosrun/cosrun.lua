local yaml = require("lyaml")
local util = require("cosrun.util")
local mount = require("cosrun.mount")
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
      print("cosrun 0.1")
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
        local _with_3 = _with_2:flag("--bios.lua")
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
local attachments
if config.env then
  attachments = (yaml.load((util.safeReadAll(".cosrun/" .. tostring(config.env) .. "/attachments.yml")) or "")) or { }
else
  attachments = { }
end
util.header("cosrun 0.1")
local self = args
local _exp_0 = self.action
if "image" == _exp_0 then
  local _exp_1 = self.image_action
  if "pack" == _exp_1 then
    util.fatarrow("Generating image for " .. tostring(self.env) .. " at " .. tostring(self.output))
    local image = { }
    local atl = (yaml.load((util.safeReadAll(".cosrun/" .. tostring(self.env) .. "/attachments.yml")) or "")) or { }
    image.attachments = atl
    image.name = self.env
    image.mountfile = util.safeReadAll(".cosrun/" .. tostring(self.env) .. "/mount.lua")
    util.safeWriteAll(self.output, yaml.dump({
      image
    }))
  elseif "unpack" == _exp_1 then
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
    util.safeWriteAll(".cosrun/" .. tostring(image.name) .. "/mount.lua", image.mountfile)
  end
elseif "environment" == _exp_0 then
  local _exp_1 = self.env_action
  if "new" == _exp_1 then
    util.fatarrow("Creating new environment: %{green}" .. tostring(self.name))
    util.safeReplaceDir(".cosrun/" .. self.name)
  elseif "delete" == _exp_1 then
    util.fatarrow("Deleting environment: %{red}" .. tostring(self.name))
    util.safeRemove(".cosrun/" .. self.name)
  elseif "rename" == _exp_1 then
    util.fatarrow("Renaming environment: %{red}" .. tostring(self.name) .. "%{white} -> %{green}" .. tostring(self.newname))
    util.safeMove(".cosrun/" .. self.name, ".cosrun/" .. self.newname)
  elseif "set" == _exp_1 then
    util.fatarrow("Using environment: %{yellow}" .. tostring(self.name))
    config.env = self.name
  end
elseif "clean" == _exp_0 then
  if not (config.env) then
    util.bangs("Environment is not set. Do `cosrun env set <name>`")
    os.exit()
  end
  if self.all then
    util.fatarrow("Clearing all files in .cosrun/" .. tostring(config.env) .. "/computer/")
    util.safeRemove(".cosrun/" .. tostring(config.env) .. "/computer/")
    util.safeMakeDir(".cosrun/" .. tostring(config.env) .. "/computer/")
  else
    if not (self.id) then
      util.bangs("ID needed to clear files")
      os.exit()
    end
    util.fatarrow("Clearing all files in .cosrun/" .. tostring(config.env) .. "/computer/" .. tostring(self.id))
    util.safeRemove(".cosrun/" .. tostring(config.env) .. "/computer/" .. tostring(self.id))
    util.safeMakeDir(".cosrun/" .. tostring(config.env) .. "/computer/" .. tostring(self.id))
  end
elseif "attach" == _exp_0 then
  local _exp_1 = self.attach_action
  if "regenerate" == _exp_1 then
    if not (config.env) then
      util.bangs("Environment is not set. Do `cosrun env set <name>`")
      os.exit()
    end
    util.arrow("Creating mount.lua...")
    mount.createMountfile(config.env, attachments)
  elseif "see" == _exp_1 then
    util.fatarrow("Showing attachments:")
    for target, path in pairs(attachments) do
      util.arrow("%{bold}" .. tostring(target) .. ": %{notBold italic}" .. tostring(path))
    end
  elseif "add" == _exp_1 then
    if config.env then
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
      attachments[self.target] = util.absolutePath(self.path)
      util.safeWriteAll(".cosrun/" .. tostring(config.env) .. "/attachments.yml", yaml.dump({
        attachments
      }))
      util.arrow("Creating mount.lua...")
      mount.createMountfile(config.env, attachments)
    else
      util.bangs("Environment is not set. Do `cosrun env set <name>`")
    end
  elseif "remove" == _exp_1 then
    if config.env then
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
      mount.createMountfile(config.env, attachments)
    else
      util.bangs("Environment is not set. Do `cosrun env set <name>`")
    end
  end
elseif "run" == _exp_0 then
  if not (config.executable) then
    util.bangs("Missing path for CraftOS-PC executable")
    os.exit()
  end
  if not (config.env) then
    util.bangs("Environment is not set. Do `cosrun env set <name>`")
    os.exit()
  end
  if not (attachments["/"]) then
    util.bangs("No / attachment. Set with `cosrun attach add <folder> --root`")
    os.exit()
  end
  util.fatarrow("Running CraftOS-PC with environment %{green}" .. tostring(config.env))
  if config.wsl.use then
    local at = ".cosrun/" .. tostring(config.env)
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
      util.arrow("Copying /rom to ID " .. tostring(self.id))
      util.safeMakeDir(tostring(at) .. "/internal/")
      util.safeCopy(bios, tostring(at) .. "/internal/bios.lua")
    end
    util.arrow("Running...")
    local command = "\"" .. tostring(config.executable) .. "\"" .. " --directory '" .. tostring(util.toWSLPath((util.absolutePath(at)), config.wsl.prefix)) .. "'" .. " --script .cosrun/" .. tostring(config.env) .. "/mount.lua" .. " --id " .. tostring(self.id) .. ((rom or bios) and " --rom .cosrun/" .. tostring(config.env) .. "/internal/" or "") .. " " .. tostring(config.flags)
    os.execute(command)
    util.arrow("Copying ID " .. tostring(self.id) .. " to root")
    util.safeCopy(tostring(at) .. "/computer/" .. tostring(self.id), root)
  else
    local at = util.absolutePath(".cosrun/" .. tostring(config.env) .. "/")
    local root = attachments['/']
    util.arrow("Copying root to ID " .. tostring(self.id))
    util.safeMakeDir(root)
    util.safeMakeDir(tostring(at) .. "/computer")
    util.safeMakeDir(tostring(at) .. "/computer/" .. tostring(self.id))
    util.safeCopy(root, tostring(at) .. "computer/" .. tostring(self.id))
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
      util.arrow("Copying /rom to ID " .. tostring(self.id))
      util.safeMakeDir(tostring(at) .. "/internal/")
      util.safeCopy(bios, tostring(at) .. "/internal/bios.lua")
    end
    util.arrow("Running...")
    local command = "\"" .. tostring(config.executable) .. "\"" .. " --directory '" .. tostring(at) .. "'" .. " --script .cosrun/" .. tostring(config.env) .. "/mount.lua" .. " --id " .. tostring(self.id) .. ((rom or bios) and " --rom .cosrun/" .. tostring(config.env) .. "/internal/" or "") .. " " .. tostring(config.flags)
    print("   " .. command)
    os.execute(command)
    util.arrow("Copying ID " .. tostring(self.id) .. " to root")
    util.safeCopy(tostring(at) .. "/computer/" .. tostring(self.id), root)
  end
end
return util.safeWriteAll("cosrun.yml", yaml.dump({
  config
}))
