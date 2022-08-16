These scripts hook into the bash/zsh/fish startup process in a way that's extensible.

### BASH

It replaces the existing `.bashrc` and `.bash_profile` with versions that scan the `~/.config/shell-hooks/startup/` and `~/.config/shell-hooks/login/` folders, and source anything that they find in there.

They then execute the original `bashrc` and/or `bash_profile` files, which will have been backed up as `~/.bashrc.backup` and `~/.bash_profile.backup` respectively.

This allows other packages to transparently hook into the bash startup process without having to modify `.bashrc` or `.bash_profile`.

### ZSH

Similar to bash, but replacing the equivalent .zsh* files.

### FISH

Similar to bash, but adds a fish config file.
