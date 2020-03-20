# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Created by Sam Deane, 05/06/2019.
# All code (c) 2019 - present day, Elegant Chaos Limited.
# For licensing terms, see http://elegantchaos.com/license/liberal/.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

if [[ "$SHELL_HOOKS_RC" == "" ]]
then

export SHELL_HOOKS_RC=1
export BASH_HOOKS_INTERACTIVE=1 #legacy
source_hooks "$SHELL_HOOKS_ROOT/interactive"
source_hooks "$SHELL_HOOKS_ROOT/interactive-$BASH_HOOKS_PLATFORM"


if [[ -e "$HOME/.zshrc.backup" ]]
then
    source "$HOME/.zshrc.backup"
fi
fi
