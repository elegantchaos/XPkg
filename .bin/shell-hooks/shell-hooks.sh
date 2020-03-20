#!/usr/bin/env bash

list_hooks () {
    hooks="$SHELL_HOOKS_ROOT/$1"
    if [[ -e "$hooks" ]]
    then
        files=$(find "$hooks/"* -exec basename {} \;)
    fi

    if [[ -e "$hooks-$SHELL_HOOKS_PLATFORM" ]]
    then
        platform=$(find "$hooks-$SHELL_HOOKS_PLATFORM/"* -exec basename {} \;)
    fi

    if [[ "$files$platform" != "" ]]
    then
        echo "$1:" $files $platform
    fi
}

if [[ "$1" == "list" ]]
then
    list_hooks "login"
    list_hooks "startup"
    list_hooks "interactive"
    list_hooks "fish"
else
    cmd=$(basename "$0")
    echo "Usage: $cmd list"
fi
