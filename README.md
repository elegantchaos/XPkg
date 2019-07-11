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

This will clone the package into a hidden location, then run any install scripts it finds in the manifest.

You can also specify a full repo URL if it's not on github.

To remove a package, `xpkg remove <package>`

To link an existing (local) directory as if it is a package: `xpkg link <package> <path>`.

For other commands, see `xpkg help`.

## Manifest

The manifest file is a json file, located at the root of the package repo, called `.xpkg.json`.

If present, this file is examined for commands to execute at install/removal time.


Currently there are two events supported: `install` and `remove`. For each of these you can list commands to execute:

```
{
    "install": [
        ["link", "file-from-repo", "path-to-link"],
        ["/some/other/binary", "some-argument"]
    ],
    "remove": [
        ["unlink", "file-from-repo", "path-to-link"]
    ]
}
```

Two internal commands are supported: `link` and `unlink`. Any other command name will be treated as an external binary, and run accordingly with the given arguments. *NB*: this is obviously powerful, but dangerous. Be careful with running arbitrary commands as you can obviously make a mess if you get them wrong.

The `link` / `unlink` commands take one or two arguments.

The first argument is the location of a file in the repo, to make a link for. If this is the only argument supplied, by default it will be linked into `~/.local/bin/`.

If you supply a second argument, you can instead link somewhere else.


## Additional Use Case

In addition to storing settings and helper scripts in packages, I have a second use case for XPkg.

Pretty much every project I work on also resides in a git repo somewhere.

Previously I used to keep pretty much everything that I was working on in a `Work/` directory, organised in a kind of reverse-dns style. Again, this became unwieldy as the amount of projects grew over time.

Having a nested structure made it tricky to see what was there.

Because everything was theoretically in git, it should have been safe to remove things that weren't currently needed, but doing everything manually made this a bit risky: it was necessary to check first to make sure that all local changes had been committed and pushed, and that there weren't things that only existed locally.

So my second use case is to manage adding/removing projects so that I can work on them when I need to, and safely remove them from a local machine when I don't.

Each project is just a package (a git repo, in other words). The only difference from the normal workflow is that when I install one, rather than hiding the local copy away somewhere, I want it to be placed into a visible location that I can point my editor/ide/tools at.

The way to do this right now is: `xpkg install <repo> --project`. This fetches the project repo and puts it into `~/Projects/<package>`, where I can work on it.

In theory, when I want to remove it, I can then do `xpkg remove <package>` and XPkg will check first to see if there are any outstanding changes. I say "in theory" because this stuff is not completed yet, and definitely not fully tested, so may well not work properly. I certainly wouldn't trust it!



## Future Plans

There are lots of things not done / not working. right now.

Some planned improvements:

- updating packages (using git pull)
- specifying versions of package
- installing multiple packages at once (a la npm/bundle/brew/etc)
- bootstrapping the install of xpkg
- updating xpkg
