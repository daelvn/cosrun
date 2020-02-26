-- cosrun
-- Wrapper around CraftOS-PC to make running projects easier
-- By daelvn
--fs      = require "filekit"
yaml    = require "lyaml"
util    = require "cosrun.util"
mount   = require "cosrun.mount"

purge = (t) ->
  unwanted = {
    "environment"
    "new"
    "delete"
    "rename"
    "run"
    "attach"
    "see"
    "add"
    "image"
    "pack"
  }
  for index in *unwanted
    t[index] = nil
  t

local args
with (require "argparse")!
  \name           "cosrun"
  \description    "Make running projects with CraftOS-PC 2 easier"
  \epilog         "https://github.com/daelvn/cosrun"
  \command_target "action"

  -- version
  with \flag "-v --version"
    \description "Prints the COSRun version"
    \action      ->
      print "cosrun 0.1"
      os.exit!

  -- config reader
  with \option "-c --config"
    \description "Configuration file for COSRun"
    \target      "config"

  -- environments
  with \command "environment env e"
    \description    "Manage COSRun environments"
    \command_target "env_action"

    -- new environment
    with \command "new n"
      \description "Creates a new environment"
      \argument    "name"

    -- delete environment
    with \command "delete del d"
      \description "Deletes an environment"
      \argument    "name"

    -- rename environment
    with \command "rename ren r"
      \description "Renames an environment"
      \argument    "name"
      \argument    "newname"

    -- set environment to use
    with \command "set s"
      \description "Sets the environment to use"
      \argument    "name"

  -- run environments
  with \command "run r"
    \description "Runs an environment"
    \argument    "env"

    -- computer id
    with \option "-i --id"
      \target  "id"
      \default 0

  -- clean environment files
  with \command "clean c"
    \description "Cleans files in an environment"

    with \argument "id"
      \description "ID to clean"
      \args        "?"
    
    with \flag "-a --all"
      \description "cleans all environments"

  -- attach folders
  with \command "attach a"
    \description    "Attaches folders to the environment"
    \command_target "attach_action"

    -- regenerate mount.lua
    with \command "regenerate regen rg"
      \description "Regenerates mount.lua"

    -- see attachments
    with \command "see s"
      \description "See attached folders"

    -- add attachment
    with \command "add a"
      \description "Attach a new folder"

      -- as root?
      with \flag "--root"
        \description "Make this folder the root of the computer"

      -- as rom?
      with \flag "--rom"
        \description "Make this folder be mounted as /root"

      -- as bios.lua
      with \flag "--bios.lua"
        \description "Make this file be used as bios.lua"
      
      -- local path
      with \argument "path"
        \description "Folder to attach"

      -- target path
      with \argument "target"
        \description "Path inside the target computer to mount"
        \args        "?"

    -- remove attachment
    with \command "remove rm r"
      \description "Removes an attachment"

      -- as root?
      with \flag "--root"
        \description "Make this folder the root of the computer"

      -- target path
      with \argument "target"
        \description "Path inside the target computer"
        \args        "?"
  
  -- images
  with \command "image img i"
    \description "Packs or runs COSRun images."
    \command_target "image_action"
    
    -- pack
    with \command "pack p"
      \description "Packs an image"

      with \argument "env"
        \description "Environment to pack"

      with \argument "output"
        \description "Output file (YAML format)"

    -- run
    with \command "unpack u"
      \description "Unpacks an image"

      with \argument "img"
        \description "Image to run"

  args = purge \parse!

-- make .cosrun
util.safeMakeDir ".cosrun"

-- read config
config         = (yaml.load (util.safeReadAll (args.config or "cosrun.yml")) or "") or {}
config.flags or= ""

-- read attachments
local attachments
if config.env
  attachments = (yaml.load (util.safeReadAll ".cosrun/#{config.env}/attachments.yml") or "") or {}
else
  attachments = {}

-- main program
util.header "cosrun 0.1"
@ = args
switch @action
  -- image
  when "image"
    switch @image_action
      when "pack"
        util.fatarrow       "Generating image for #{@env} at #{@output}"
        image             = {}
        atl               = (yaml.load (util.safeReadAll ".cosrun/#{@env}/attachments.yml") or "") or {}
        image.attachments = atl
        image.name        = @env
        image.mountfile   = util.safeReadAll ".cosrun/#{@env}/mount.lua"
        util.safeWriteAll @output, yaml.dump {image}
      when "unpack"
        util.fatarrow       "Unpacking image: %{yellow}#{@img}"
        image = (yaml.load (util.safeReadAll @img) or "") or {}
        util.arrow          "Image name: %{green}#{image.name}"
        util.safeReplaceDir ".cosrun/"..image.name
        for inside, outside in pairs image.attachments do util.arrow "Attachment: %{green}#{inside}%{white} -> %{yellow}#{outside}"
        util.safeWriteAll   ".cosrun/#{image.name}/attachments.yml", yaml.dump {image.attachments}
        util.safeWriteAll   ".cosrun/#{image.name}/mount.lua",       image.mountfile
  -- environment
  when "environment"    
    switch @env_action
      when "new"
        util.fatarrow       "Creating new environment: %{green}#{@name}"
        util.safeReplaceDir ".cosrun/"..@name
      when "delete"
        util.fatarrow       "Deleting environment: %{red}#{@name}"
        util.safeRemove     ".cosrun/"..@name
      when "rename"
        util.fatarrow       "Renaming environment: %{red}#{@name}%{white} -> %{green}#{@newname}"
        util.safeMove       ".cosrun/"..@name, ".cosrun/"..@newname
      when "set"
        util.fatarrow       "Using environment: %{yellow}#{@name}"
        config.env          = @name
  -- clean
  when "clean"
    unless config.env
      util.bangs "Environment is not set. Do `cosrun env set <name>`"
      os.exit!
    if @all
      util.fatarrow    "Clearing all files in .cosrun/#{config.env}/computer/"
      util.safeRemove  ".cosrun/#{config.env}/computer/"
      util.safeMakeDir ".cosrun/#{config.env}/computer/"
    else
      unless @id
        util.bangs "ID needed to clear files"
        os.exit!
      util.fatarrow    "Clearing all files in .cosrun/#{config.env}/computer/#{@id}"
      util.safeRemove  ".cosrun/#{config.env}/computer/#{@id}"
      util.safeMakeDir ".cosrun/#{config.env}/computer/#{@id}"
  -- attach
  when "attach"
    switch @attach_action
      when "regenerate"
        unless config.env
          util.bangs "Environment is not set. Do `cosrun env set <name>`"
          os.exit!
        util.arrow "Creating mount.lua..."
        mount.createMountfile config.env, attachments
      when "see"
        util.fatarrow "Showing attachments:"
        for target, path in pairs attachments
          util.arrow "%{bold}#{target}: %{notBold italic}#{path}"
      when "add"
        if config.env
          @target = "/"        if @root
          @target = "/rom"     if @rom
          @target = "bios.lua" if @bios
          util.fatarrow "Attaching %{yellow}#{@path}%{white} as %{green}#{@target}"
          attachments[@target] = util.absolutePath @path
          util.safeWriteAll ".cosrun/#{config.env}/attachments.yml", yaml.dump {attachments}
          util.arrow "Creating mount.lua..."
          mount.createMountfile config.env, attachments
        else
          util.bangs "Environment is not set. Do `cosrun env set <name>`"
      when "remove"
        if config.env
          @target = "/"        if @root
          @target = "/rom"     if @rom
          @target = "bios.lua" if @bios
          util.fatarrow "Removing attachment for #{@target}"
          attachments[@target] = nil
          util.safeWriteAll ".cosrun/#{config.env}/attachments.yml", yaml.dump {attachments}
          util.arrow "Creating mount.lua..."
          mount.createMountfile config.env, attachments
        else
          util.bangs "Environment is not set. Do `cosrun env set <name>`"
  when "run"
    unless config.executable
      util.bangs "Missing path for CraftOS-PC executable"
      os.exit!
    unless config.env
      util.bangs "Environment is not set. Do `cosrun env set <name>`"
      os.exit!
    -- find / attachment
    unless attachments["/"]
      util.bangs "No / attachment. Set with `cosrun attach add <folder> --root`"
      os.exit!
    -- run
    util.fatarrow "Running CraftOS-PC with environment %{green}#{config.env}"
    if config.wsl.use
      at   = ".cosrun/#{config.env}"
      root = attachments['/']
      -- Copy
      util.arrow "Copying root to ID #{@id}"
      util.safeMakeDir root
      util.safeMakeDir "#{at}/computer"
      util.safeMakeDir "#{at}/computer/#{@id}"
      util.safeCopy root, "#{at}/computer/#{@id}"
      local rom, bios
      if attachments["/rom"]
        rom = attachments["/rom"]
        util.arrow "Copying /rom to ID #{@id}"
        util.safeMakeDir "#{at}/internal/"
        util.safeMakeDir "#{at}/internal/rom/"
        util.safeCopy    rom, "#{at}/internal/rom/"
      if attachments["bios.lua"]
        bios = attachments["bios.lua"]
        util.arrow "Copying /rom to ID #{@id}"
        util.safeMakeDir "#{at}/internal/"
        util.safeCopy    bios, "#{at}/internal/bios.lua"
      -- Run
      util.arrow "Running..."
      command = "\"#{config.executable}\"" ..
                " --directory '#{util.toWSLPath (util.absolutePath at), config.wsl.prefix}'" ..
                " --script .cosrun/#{config.env}/mount.lua" ..
                " --id #{@id}" ..
                ((rom or bios) and " --rom .cosrun/#{config.env}/internal/" or "") ..
                " #{config.flags}"
      os.execute command
      -- Copy back
      util.arrow "Copying ID #{@id} to root"
      util.safeCopy "#{at}/computer/#{@id}", root
    else
      at   = util.absolutePath ".cosrun/#{config.env}/"
      root = attachments['/']
      -- Copy
      util.arrow "Copying root to ID #{@id}"
      util.safeMakeDir root
      util.safeMakeDir "#{at}/computer"
      util.safeMakeDir "#{at}/computer/#{@id}"
      util.safeCopy root, "#{at}computer/#{@id}"
      local rom, bios
      if attachments["/rom"]
        rom = attachments["/rom"]
        util.arrow "Copying /rom to ID #{@id}"
        util.safeMakeDir "#{at}/internal/"
        util.safeMakeDir "#{at}/internal/rom/"
        util.safeCopy    rom, "#{at}/internal/rom/"
      if attachments["bios.lua"]
        bios = attachments["bios.lua"]
        util.arrow "Copying /rom to ID #{@id}"
        util.safeMakeDir "#{at}/internal/"
        util.safeCopy    bios, "#{at}/internal/bios.lua"
      -- Run
      util.arrow "Running..."
      command = "\"#{config.executable}\"" ..
                " --directory '#{at}'" ..
                " --script .cosrun/#{config.env}/mount.lua" ..
                " --id #{@id}" ..
                ((rom or bios) and " --rom .cosrun/#{config.env}/internal/" or "") ..
                " #{config.flags}"
      print "   "..command
      os.execute command
      -- Copy back
      util.arrow "Copying ID #{@id} to root"
      util.safeCopy "#{at}/computer/#{@id}", root

-- rewrite config
util.safeWriteAll "cosrun.yml", yaml.dump {config}