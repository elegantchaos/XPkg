if [[ -e "$HOME/.bashrc" ]]
then
    source "$HOME/.bashrc"
fi

if [[ "$SHELL_HOOKS_LOGIN" == "" ]]
then
    export SHELL_HOOKS_LOGIN=1
    export BASH_HOOKS_LOGIN=1 # legacy

    source_hooks "$SHELL_HOOKS_ROOT/login"
    source_hooks "$SHELL_HOOKS_ROOT/login-$SHELL_HOOKS_PLATFORM"

    if [[ -e "$HOME/.bash_profile.backup" ]]
    then
        source "$HOME/.bash_profile.backup"
    fi
fi
