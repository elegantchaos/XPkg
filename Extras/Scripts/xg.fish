complete --no-files --command xg -n "not __fish_seen_subcommand_from (__fish_xg_complete_packages)" --arguments "(__fish_xg_complete_packages)"

function __fish_xg_complete_packages
  xpkg list --compact
end

function xg
  set -l directory (xpkg path $argv)
  pushd $directory
end
