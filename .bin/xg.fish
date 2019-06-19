complete -c xg -e -a "(__fish_xg_packages)"

function __fish_xg_packages
  xpkg list --compact
end

function xg
  set -l directory (xpkg path $argv)
  pushd $directory
end
