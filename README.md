# COSRun

COSRun is a project that makes running projects in [CraftOS-PC](https://www.craftos-pc.cc) much easier, by letting you use environments and using features such as CraftOS-PC mounts.

## Installation

You can install this using LuaRocks:

```sh
$ luarocks install cosrun
```

Alternatively, clone the repo and run `luarocks make`:

```sh
$ git clone daelvn/cosrun
$ luarocks make
```

## Usage

> You can get a full list of commands with `cosrun -h` or `cosrun <command> -h`

Before using COSRun, you have to create a `cosrun.yml` file in your working directory. This will contain the executable path and other options.

```yaml
executable: /mnt/c/Program Files/CraftOS-PC/CraftOS-PC.exe
# skip this if you're not on wsl
wsl:
  use:    true
  prefix: \\wsl$\Alpine\
# this is optional
flags: ''
```

To start a new environment and then change to it, use:

```sh
$ cosrun env new <name>
$ cosrun env set <name>
```

Then, you can attach folders to it. You need to attach at least root to run it. Let's attach two folders.

```sh
### cosrun attach add path/ --root
### cosrun attach add path/ insidepath/
$ cosrun attach add project/src/ --root
$ cosrun attach add project/lib/ /lib/
```

Now you can run it with: (ID defaults to 0, change that with `--id` option.)

```sh
$ cosrun run <name>
```

When a COSRun project runs, it copies the files from your root path to the computer ID root, and then mounts the rest of folders using CraftOS-PC's `mounter` API. It isn't recommended that you edit files in your source code while it's running or you could lose changes. Other mounts that aren't root don't need copying because CraftOS-PC works directly in them instead of copying them over.

If you want to clear the files *inside* the computer, use `clean`:

```sh
# Don't worry, this doesn't delete source files
$ cosrun clean <id>
$ cosrun clean --all # only if you want to delete all files
```

If you want to share your project, instead of copying the `.cosrun` folder, just create an image like this:

```sh
$ cosrun image pack <env> project.yml
```

Then someone else can clone your repo, unpack the image and run it like this:

```sh
$ git clone you/your-amazing-repo
$ cosrun image unpack amazing-project.yml
$ cosrun run amazing-project
```

### Merging projects

You can use several projects in the same emulator by using `cosrun image import`:

```sh
$ cosrun image import child.yml 0      # cosrun img import <img> <id>
$ cosrun run parent
```

## License

See LICENSE.md.

Basically: This project, filekit and ansikit are Unlicensed. LuaFileSystem uses its own. argparse and lyaml are MIT.