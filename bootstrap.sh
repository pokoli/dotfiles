#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
	rsync --exclude ".git/" --exclude "ssh-config" --exclude "bootstrap.sh" \
		--exclude "trytond.conf" --exclude "i3" -avh --no-perms . ~;
    mkdir -p ~/.config/i3/;
	rsync -avh ./i3/ ~/.config/i3/;
	source ~/.zshrc;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
