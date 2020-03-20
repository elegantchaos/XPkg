set -x SHELL_HOOKS_SHELL fish
set -x SHELL_HOOKS_RC 1
set -x SHELL_HOOKS_PLATFORM (uname)
set -x SHELL_HOOKS_ROOT "$HOME/.local/share/shell-hooks"
set -x SHELL_HOOKS_INTERACTIVE 1

# Source a hook
# Before sourcing, we change the working directory to the true
# location of the hook file. This allows hooks to reference other
# local resources just using ./my-resource
function source_hook
  set -l absolute (readlink "$argv[1]")
  set -l container (dirname "$absolute")
  pushd "$container" > /dev/null
  source "$absolute"
  popd > /dev/null
end


# Source each hook in a folder.
function source_hooks
  set -l folder $argv[1]
  if test -e $folder
      for f in $folder/*
          source_hook $f
      end
  end
end

source_hooks "$SHELL_HOOKS_ROOT/fish"
source_hooks "$SHELL_HOOKS_ROOT/fish-$SHELL_HOOKS_PLATFORM"
