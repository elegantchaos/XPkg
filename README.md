# xpkg

A simple cross-platform "package" manager.

## Overview

I tend to set up many aspects of my environment in a similar way, whether I'm on Linux, macOS, or some other unix-like.

As part of this, I have a whole grab-bag of scripts, configuration files, and the like, which I need to somehow download, install, and then quite often sym-link into various locations.

Previously I've done this by having a single git repo that I clone, and a bunch of scripts within it that I hook up to things like `.bashrc` in order to get everything working.

This isn't a very scalable solution, and I wanted something better.

Specifically I wanted to be able to:

- split the monolithic dump of tools and scripts into individual packages
- have each package live in a git repo
- easily install or remove a package
- have hooks automatically run when a package is installed, to set up symlinks etc
- have similar hooks run automatically to clean up when a package is removed

In a nutshell, that's what XPkg does.

## Installation

**Disclaimer: XPkg was developed purely for my own use. It is under active (albeit sporadic) development and probably has bugs in it. It will modify your `.bashrc`, `.zshrc` etc scripts, and although it backs them up, it may break things. Please do tell me if it does something wrong, but I can't guarantee to support you, and I definitely won't be held responsible for any damage it does. Use XPkg at your own risk!**

### Dependencies

When bringing up a new machine, Xpkg is one of the first things I install - and I then use it to install lots of other things.

There one or two things that it does require first, however:

- git
- swift (or Xcode)
- github access (ideally via ssh, which means you need to set up your ssh keys for the machine and register them with github)


### Bootstrap

Running `curl https://raw.githubusercontent.com/elegantchaos/XPkg/main/Extras/Scripts/bootstrap | bash` should get you up and running.

What this does is:
- clone the project into `.local/share/xpkg`
- build it
- install some hooks to link it in to your path
- prompt you to open a new shell or terminal

During installation, an alias to xpkg is installed into `~/.local/bin`, and some startup hooks are installed for `bash`, `zsh` and `fish` which include this location in `$PATH`.

*You need to start a new shell / open a new terminal window before this path change is picked up.*



## Usage

To install a package from Github: `xpkg install <user/repo>`.

This will clone the package into a hidden location, then run its installer.

You can also specify a full repo URL if it's not on github.

To remove a package, `xpkg remove <package>`.

To list the installed packages `xpkg list`.

To navigate to a package directory (using `pushd`), type `xg <package>`.

For other commands, see `xpkg help`.

## Writing Packages

At their most basic, packages are just git repositories, which contain a payload (whatever files you want to install or hook into your system), plus an installer (that tells XPkg how to install/uninstall the payload).

XPkg was designed to be cross-platform (this is what the "X" stands for), and is written in Swift. It should work on any platform that has a working Swift compiler and standard libraries. Since Swift is a requirement for XPkg itself, I decided to also make it a requirement for the installer.[^1]

In fact, XPkg packages are also Swift Package Manager (SPM) packages.

When you install a package with XPkg, it clones the corresponding repository, then uses SPM to build and run the installer (a product with a special name, currently `<your-package-name>-xpkg-hooks`) in your package, passing it a known set of arguments and environment variables.

There are two nice aspects of this design choice:

- Your installer can do whatever it wants when it is run; it's just code!
- We get dependency management for free
  - the installer can list other SPM packages as dependencies, and use them when its run
  - it can also list other _XPkg_ packages as dependencies; SPM will pull them in, and XPkg will notice that they've been pulled in and install them!

Of course, there are some things that you commonly want to do when installing a package, such as creating symbolic links to places like `/usr/local/bin`, running other scripts, etc.

To avoid every installer having to write that code every time, we just put them in another Swift package (currently called `XpkgPackage`) which all installers can import and use.

[^1]: The first iteration of XPkg didn't have installers, it had manifests. The manifest was a hidden json file called `.xpkg.json` which sat at the root of package and described how to install/uninstall the package. This was lightweight, but a little inflexible, since it was up to XPkg to interpret the manifest. You could run code by invoking shell scripts, but you couldn't specify a requirement for other packages as dependencies.

[^2]: Note that the package can be a real swift package, designed for use in building Swift products, and with a other products and targets. It doesn't have to be, but it can be.

### Example

A simple package might consist of the following files:

    my-package/
      Package.swift
      Sources/xpkg-my-package/
        main.swift
      Payload/
        my-command.sh

The `Package.swift` file might look like this:

```Swift

// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "my-package",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "my-package-xpkg-hooks", targets: ["my-package-xpkg-hooks"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/XPkgPackage", from:"1.0.5"),
    ],
    targets: [
        .target(
            name: "my-package-xpkg-hooks",
            dependencies: ["XPkgPackage"]),
    ]
)
```

The `main.swift` file might look like this:

```Swift
import XPkgPackage

let links = [
    ["Payload/my-command.sh"]
]

let arguments = CommandLine.arguments
let package = InstalledPackage(fromCommandLine: arguments)
try! package.performAction(fromCommandLine: CommandLine.arguments, links: links, commands: [])
```

This uses the functionality provided by XPkgPackage to install a link `my-command` into `/usr/local/bin`, which points to the file `Payload/my-command.sh` in the cached version of the package on the disk.

### A Note About Terminology

XPkg has undergone a major redesign, and the terminology hasn't caught up yet.

Previously we had packages and manifests. Now we have packages and installers.

I plan to rename a lot of things to reflect the new reality:

  - `xpkg-hooks` will probably become `xpkg-installer`
  - `XPkgPackage` will probably become `XPkgInstaller`

### Hooking Into Shell Startup

Something that many packages need to do is to hook into the shell startup process (be it .bashrc, .zshrc, or whatever), in order to set environment variables, aliases, and so on.

Rather than have each package modify these init files, which could get messy, I decided to have one package install itself into this startup process, and have this package provide a flexible way to install other hooks.

This package is called `shell-hooks` (https://github.com/elegantchaos/shell-hooks), and is installed by default when you install XPkg itself.

It hooks itself into the startup process for Bash, Zsh, and Fish. At startup, it scans `~/.config/shell-hooks/` and runs any files that it finds there. It actually uses subdirectories and pattern matching to choose exactly which files to run, depending on what platform you're on, and whether this is an interative or non-interactive session.

The standard installer support package `XpkgPackage` knows about shell-hooks, and provides support for installing symbolic links into its directories. This makes it really simple for Xpkg packages to insert themselves into the shell startup process.


## Existing Packages

I'm slowly converting over my tangle of old scripts and links to packages, and have a bunch that I've made, supporting things like:

- Atom setup
- Travis helpers
- Git configs and helpers
- Terminal setup
- Xcode templates
- Coding fonts
- Homebrew installation
- Swift helpers
- Mouse helpers (for Linux)
- Tabtab support (for Linux)
- Keyboard support (for Linux)
- VIM settings
- Appledoc helpers
- Conky settings

Many of these are in private repos, because they're basically _my_ settings, but you'll find a few public on github. I will try to open up more over time, I just need to make sure that they don't accidentally contain private tokens or other stuff not-for-general-consumption.


## How It Works

XPkg basically creates a local swift package in a hidden directory, and maintains a `Package.swift` file in there.

When you install a package, XPkg adds it to the `Package.swift` file, and uses `swift update` to resolve it and fetch the dependencies.

It then spots any packages that got added as a result of this, and tries to build and run the installer for them.

Package removal works in a similar way, in reverse.

There's a bit more to it than that, but that's the basic idea.

Using SPM to do all the dependency resolution and fetching seemed like a good way to get a lot of fuctionality for not a lot of work!

The idea is potentially pretty solid I think, and would be purely an implementation detail if it weren't for the fact that the use of SPM is exposed as a way to provide the installers. In theory other installer mechanisms could be provided instead / as well.

  During development, I've found that occasionally bugs in XPkg itself can cause the auto-generated `Package.swift` to become corrupted and need hand editing. This is obviously not ideal for something that other people would use, but it should be possible to prevent this corruption from happening when XPkg itself settles down.


## Future Plans

As well as supporting installation, XPkg was originally intended to help with some other things:

- installing and navigating to work projects on my machine (eg being able to type `xg MyProject` and cd to my working directory for MyProject)
- automatically fetching / pull a list of tracked git repos (both packages and projects)
- automatically backing up / pushing a list of tracked git repos (both packages and projects)

This is all intended to help support an existence where you are working on multiple machines at the same time / moving regularly between machines.

Some of these features are in the pipeline, or may be added at a later date.

XPkg also used to install itself into `/usr/local/share`, and install links etc into `/usr/local/bin`. At some point I moved over into using `~/.local/` instead. At some point I intend to make it support either, depending on a configuration flag. At some point. Maybe...
