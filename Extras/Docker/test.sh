#!/usr/bin/env bash

# Download and run the bootstrap script
curl https://raw.githubusercontent.com/elegantchaos/XPkg/development/Extras/Scripts/bootstrap | bash

#cat ~/.bashrc
cat ~/.profile
#ls ~/.local/share/xpkg/

# Test xpkg
bash -l -c "xpkg list"
