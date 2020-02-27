-- cosrun
-- Wrapper around CraftOS-PC to make running projects easier
-- By daelvn
--fs      = require "filekit"
yaml    = require "lyaml"
fs      = require "filekit"
util    = require "cosrun.util"
mount   = require "cosrun.mount"

VERSION = "0.4"

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
      print "cosrun #{VERSION}"
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

    with \flag "-i --imports"
      \description "only cleans imports in environment"

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
      with \flag "--bios"
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

    -- unpack
    with \command "unpack u"
      \description "Unpacks an image"

      with \argument "img"
        \description "Image to unpack"

    -- import
    with \command "import i"
      \description "Copies files from image into current environment"

      with \argument "img"
        \description "Image to import"

      with \argument "id"
        \description "ID to import the files to"
        \convert     tonumber
        \default     0

      with \option "-d --dir"
        \description "Changes the root directory for the import"

  args = purge \parse!

-- make .cosrun
util.safeMakeDir ".cosrun"

-- read config
config         = (yaml.load (util.safeReadAll (args.config or "cosrun.yml")) or "") or {}
config.flags or= ""

-- attachment loading function
loadAttachments = (env) -> (yaml.load (util.safeReadAll ".cosrun/#{env}/attachments.yml") or "") or {}

-- main program
util.header "cosrun #{VERSION}"
@ = args

errorEnv = ->
  unless config.env
    util.bangs "Environment is not set. Do `cosrun env set <name>`"
    os.exit!

packImage = ->
  util.fatarrow       "Generating image for #{@env} at #{@output}"
  image             = {}
  atl               = loadAttachments @env
  image.attachments = atl
  image.name        = @env
  image.mountfile   = util.safeReadAll ".cosrun/#{@env}/mount.lua"
  util.safeWriteAll @output, yaml.dump {image}

unpackImage = ->
  util.fatarrow       "Unpacking image: %{yellow}#{@img}"
  image = (yaml.load (util.safeReadAll @img) or "") or {}
  util.arrow          "Image name: %{green}#{image.name}"
  util.safeReplaceDir ".cosrun/"..image.name
  for inside, outside in pairs image.attachments do util.arrow "Attachment: %{green}#{inside}%{white} -> %{yellow}#{outside}"
  util.safeWriteAll   ".cosrun/#{image.name}/attachments.yml", yaml.dump {image.attachments}
  util.safeWriteAll   ".cosrun/#{image.name}/mount.lua",       image.mountfile

local addAttach
importImage = ->
  errorEnv!
  at               = ".cosrun/#{config.env}/import"
  util.safeMakeDir at
  util.fatarrow    "Importing image: %{yellow}#{@img}"
  image = (yaml.load (util.safeReadAll @img) or "") or {}
  util.arrow       "Image name: %{green}#{image.name}"
  util.safeMakeDir "#{at}/computer"
  util.safeMakeDir "#{at}/computer/#{@id}"
  for inside, outside in pairs image.attachments
    if @dir
      outside = fs.combine @dir, outside
    util.arrow     "Importing %{yellow}#{outside}%{white} -> %{green}#{inside}"
    switch inside
      when "bios.lua"
        util.safeMakeDir "#{at}/internal"
        util.safeCopy    outside, "#{at}/internal/bios.lua"
      when "/rom"
        util.safeMakeDir "#{at}/internal"
        util.safeMakeDir "#{at}/internal/rom"
        util.safeCopy    outside, "#{at}/internal/rom/"
      when "/"
        util.safeCopy outside, "#{at}/computer/#{@id}/"
      else
        @path, @target = outside, inside
        addAttach!
        --util.safeCopy outside, "#{at}/computer/#{@id}/#{inside}"

newEnv = ->
  util.fatarrow       "Creating new environment: %{green}#{@name}"
  util.safeReplaceDir ".cosrun/"..@name

deleteEnv = ->
  util.fatarrow       "Deleting environment: %{red}#{@name}"
  util.safeRemove     ".cosrun/"..@name

renameEnv = ->
  util.fatarrow       "Renaming environment: %{red}#{@name}%{white} -> %{green}#{@newname}"
  util.safeMove       ".cosrun/"..@name, ".cosrun/"..@newname

setEnv = ->
  util.fatarrow       "Using environment: %{yellow}#{@name}"
  config.env          = @name

clean = (env, prefix) ->
  errorEnv!
  if (not (@all or @imports)) and (not prefix)
    util.bangs "ID needed to remove files"
    os.exit!
  if @all
    util.fatarrow    "Cleaning all files in .cosrun/#{env}/"
    util.safeRemove  ".cosrun/#{env}/"
    util.safeMakeDir ".cosrun/#{env}/"
  elseif @imports
    util.fatarrow    "Cleaning all imports in .cosrun/#{env}/"
    util.safeRemove  ".cosrun/#{env}/import/"
    util.safeMakeDir ".cosrun/#{env}/import/"
  else
    util.fatarrow    "Cleaning all files in .cosrun/#{env}/computer/#{prefix}"
    util.safeRemove  ".cosrun/#{env}/computer/#{prefix}"
    util.safeMakeDir ".cosrun/#{env}/computer/#{prefix}"

regenMount = ->
  errorEnv!
  util.arrow "Creating mount.lua..."
  mount.createMountfile config.env, loadAttachments config.env

seeAttaches = ->
  util.fatarrow "Showing attachments:"
  for target, path in pairs loadAttachments config.env
      util.arrow "%{bold}#{target}: %{notBold italic}#{path}"

addAttach = ->
  attachments = loadAttachments config.env
  errorEnv!
  @target = "/"        if @root
  @target = "/rom"     if @rom
  @target = "bios.lua" if @bios
  util.fatarrow "Attaching %{yellow}#{@path}%{white} as %{green}#{@target}"
  --attachments[@target] = util.absolutePath @path
  attachments[@target] = @path
  util.safeWriteAll ".cosrun/#{config.env}/attachments.yml", yaml.dump {attachments}
  util.arrow "Creating mount.lua..."
  mount.createMountfile config.env, attachments

removeAttach = ->
  attachments = loadAttachments config.env
  errorEnv!
  @target = "/"        if @root
  @target = "/rom"     if @rom
  @target = "bios.lua" if @bios
  util.fatarrow "Removing attachment for #{@target}"
  attachments[@target] = nil
  util.safeWriteAll ".cosrun/#{config.env}/attachments.yml", yaml.dump {attachments}
  util.arrow "Creating mount.lua..."
  mount.createMountfile config.env, attachments

subrun = (wsl) ->
  attachments = loadAttachments config.env
  at          = ".cosrun/#{@env}"
  root        = attachments['/']
  -- Import
  if fs.exists "#{at}/import"
    util.arrow "Copying imports..."
    util.safeCopy "#{at}/import", at
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
    util.arrow "Copying bios.lua to ID #{@id}"
    util.safeMakeDir "#{at}/internal/"
    util.safeCopy    bios, "#{at}/internal/bios.lua"
  -- Run
  util.arrow "Running..."
  command = "\"#{config.executable}\"" ..
            (wsl and " --directory '#{util.toWSLPath (util.absolutePath at), config.wsl.prefix}'" or " --directory '#{at}'") ..
            " --script .cosrun/#{@env}/mount.lua" ..
            " --id #{@id}" ..
            ((rom or bios) and " --rom .cosrun/#{@env}/internal/" or "") ..
            " #{config.flags}"
  --print "   " .. command
  os.execute command
  -- Copy back
  -- As of 0.3, root is not copied back anymore
  --util.arrow "Copying ID #{@id} to root"
  --util.safeCopy "#{at}/computer/#{@id}", root

run = ->
  unless config.executable
    util.bangs "Missing path for CraftOS-PC executable"
    os.exit!
  -- Setenv
  util.arrow "Setting environment to #{@env}"
  config.env = @env
  -- Clean
  clean @env, @id
  -- Attachments
  attachments = loadAttachments config.env
  unless attachments["/"]
    util.bangs "No / attachment. Set with `cosrun attach add <folder> --root`"
    os.exit!
  -- run
  util.fatarrow "Running CraftOS-PC with environment %{green}#{@env}"
  subrun config.wsl.use

switch @action
  when "image"
    switch @image_action
      when "pack"   then packImage!
      when "unpack" then unpackImage!
      when "import" then importImage!
  
  when "environment"    
    switch @env_action
      when "new"    then newEnv!
      when "delete" then deleteEnv!   
      when "rename" then renameEnv!
      when "set"    then setEnv!
  
  when "clean" then clean config.env, @id

  when "attach"
    switch @attach_action
      when "regenerate" then regenMount!
      when "see"        then seeAttaches!    
      when "add"        then addAttach!
      when "remove"     then removeAttach!
  
  when "run" then run!

-- rewrite config
util.safeWriteAll "cosrun.yml", yaml.dump {config}