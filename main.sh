#! /bin/bash

CONFIG_FILE="config.json"
ENV_PATH=$(jq -r '.config.env' $CONFIG_FILE)

source $HOME/$ENV_PATH


### INSTALL, DELETE APPS

delete() {
	APPS_DELETE=$(jq -r '.apps.delete[]' $CONFIG_FILE)

	for i in ${APPS_DELETE[@]}; do
	  	sudo apt-get remove $i -y
	done
}

install() {
	APPS_INSTALL=$(jq -r '.apps.install[]' $CONFIG_FILE)

	for i in ${APPS_INSTALL[@]}; do
	  	sudo apt-get install $i -y
	done
}

install_flatpak() {
	APPS_INSTALL_FLATPAK=$(jq -r '.apps.install_flatpak[]' $CONFIG_FILE)

	for i in ${APPS_INSTALL_FLATPAK[@]}; do
	  	flatpak install flathub $i
	done
}

install_golang() {
	echo "install_golang"
}


### CONFIGURE SYSTEM

configure_themes_and_icons() {
	# theme
	THEME_PATH=$(jq -r '.config.theme.path' $CONFIG_FILE)
	THEME_NAME=$(jq -r '.config.theme.name' $CONFIG_FILE)

	sudo mkdir $HOME/.themes
	sudo chmod 777 $HOME/.themes
	tar -C $HOME/.themes -xf $HOME/$THEME_PATH
	gsettings set org.gnome.desktop.interface gtk-theme $THEME_NAME

	# icons
	ICONS_PATH=$(jq -r '.config.icons.path' $CONFIG_FILE)
	ICONS_NAME=$(jq -r '.config.icons.name' $CONFIG_FILE)

	sudo mkdir $HOME/.icons
	sudo chmod 777 $HOME/.icons
	tar -C $HOME/.icons -xf $HOME/$ICONS_PATH
	gsettings set org.gnome.desktop.interface icon-theme $ICONS_NAME
}

configure_hotkeys() {
	HOTKEYS=$(jq -r '.hotkeys.keybindings' $CONFIG_FILE)
	keys=$(echo $HOTKEYS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $HOTKEYS | jq -r ".$key")
		gsettings set org.gnome.desktop.wm.keybindings $key $value
	done

	# gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>AudioPlay']"
}


### CONFIGURE APPS

configure_megacmd() {
    mega-login $MEGA_LOGIN $MEGA_PASSWORD
}

configure_alacritty() {
	ALACRITTY_PATH=$(jq -r '.config.alacritty' $CONFIG_FILE)
	sudo mkdir $HOME/.config/alacritty
	sudo chmod 777 $HOME/.config/alacritty
	sudo cp $ALACRITTY_PATH $HOME/.config/alacritty/
}

configure_git() {
	git config --global user.name $GIT_LOGIN
	git config --global user.email $GIT_EMAIL
	git config --global core.editor code
	git config --global init.defaultBranch main
}


### DOWNLOAD

download_folders_from_mega() {
	MEGA_DOWNLOAD_FOLDERS=$(jq -r '.mega.download_folders[]' $CONFIG_FILE)

	for i in ${MEGA_DOWNLOAD_FOLDERS[@]}; do
	  	mega-get /$i $HOME
	done
}

download_notes() {
	NOTES_PATH=$(jq -r '.notes.path' $CONFIG_FILE)
	NOTES_FOLDER=$(jq -r '.notes.name' $CONFIG_FILE)

	if test -d $HOME/$NOTES_PATH; then
		mkdir $HOME/$NOTES_PATH/$NOTES_FOLDER
		git clone $NOTES_GIT_LINK $HOME/$NOTES_PATH/$NOTES_FOLDER
	else
		echo "Directory $NOTES_PATH does not exist"
	fi
}


### OTHER

create_venv_python() {
	VENV_PATH=$(jq -r '.paths.venv' $CONFIG_FILE)
	python3 -m venv $HOME/$VENV_PATH
}

add_aliases() {
	ALIASES=$(jq -r '.aliases' $CONFIG_FILE)
	keys=$(echo $ALIASES | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $ALIASES | jq -r ".$key")
		echo "alias $key='$value'" >> ~/.bashrc
	done
}


main() {
	# delete
	# install
	# install_flatpak
	# install_golang

	# configure_themes_and_icons
	# configure_hotkeys

	# configure_megacmd
	# configure_alacritty
	# configure_git

	# download_folders_from_mega
	# download_notes

	# create_venv_python
	# add_aliases
}

main