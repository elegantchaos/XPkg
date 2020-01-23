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

Running `curl https://raw.githubusercontent.com/elegantchaos/XPkg/master/.bin/bootstrap | bash` should get you up and running.

What this does is:
- clone the project into `.local/share/xpkg`
- build it
- install some hooks to link it in to your path
- install a couple of essential packages


## Usage

To install a package from Github: `xpkg install <user/repo>`.

This will clone the package into a hidden location, then run its installer.

You can also specify a full repo URL if it's not on github.

To remove a package, `xpkg remove <package>`

To list the installed packages `xpkg list`

For other commands, see `xpkg help`.

## Writing Packages

At their most basic, packages are just git repositories, which contain a payload (whatever files you want to install or hook into your system), plus an installer (that tells XPkg how to install/uninstall the payload).

XPkg was designed to be cross-platform (this is what the "X" stands for), and is written in Swift. It should work on any platform that has a working Swift compiler and standard libraries. Since Swift is a requirement for XPkg itself, I decided to also make it a requirement for the installer.[^1]

In fact, XPkg packages are also SPM (Swift Package Manager) packages.

When you install a package with XPkg, it clones the corresponding repository, then uses SPM to build and run the installer (a product with a special name, currently `<your-package-name>-xpkg-hooks`) in your package, passing it a known set of arguments and environment variables.

There are two nice aspects of this design choice:

- Your installer can do whatever it wants when it is run; it's just code!
- We get dependency management for free
  - the installer can list other XPkg packages as dependencies, and use them when its run
  - it can also list other _SPM_ packages as dependencies; SPM will pull them in, and XPkg will notice that they've been pulled in and install them!

Of course, there are some things that you commonly want to do when installing a package, such as creating symbolic links to places like `/usr/local/bin`, running other scripts, etc.

To avoid every installer having to write that code every time, we just put them in another Swift package (currently called `XpkgPackage`) which all installers can import and use.

[^1]: The first iteration of XPkg didn't have installers, it had manifests. The manifest was a hidden json file called `.xpkg.json` which sat at the root of package and described how to install/uninstall the package. This was lightweight, but a little inflexible, since it was up to XPkg to interpret the manifest. You could run code by invoking shell scripts, but you couldn't specify a requirement for other packages as dependencies.

[^2]: Note that the package can be a real swift package, designed for use in building Swift products, and with a other products and targets. It doesn't have to be, but it can be.

### Example

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

Previously we had packages and manifests. Now we have packages and installers. I plan to rename a lot of things to reflect the new reality.


## Future Plans

There are lots of things not done / not working. right now.

Some planned improvements:

- updating packages (using git pull)
- specifying versions of package
- installing multiple packages at once (a la npm/bundle/brew/etc)
- bootstrapping the install of xpkg
- updating xpkg
