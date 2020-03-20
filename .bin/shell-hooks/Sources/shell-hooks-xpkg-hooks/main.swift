import XPkgPackage

let links = [
    ["bashrc", "~/.bashrc"],
    ["bash_profile", "~/.bash_profile"],
    ["shell-hooks.sh", "~/.local/bin/hooks"],
    ["zshenv", "~/.zshenv"],
    ["zshrc", "~/.zshrc"],
    ["zshlogin", "~/.zshlogin"],
    ["zshlogout", "~/.zshlogout"],
    ["fish", "~/.config/fish/config.fish"]
]

let package = InstalledPackage(fromCommandLine: CommandLine.arguments)
try! package.performAction(fromCommandLine: CommandLine.arguments, links: links)
