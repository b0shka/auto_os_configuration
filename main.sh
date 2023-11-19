#! /bin/bash

sudo apt-get install jq -y

HOME_DIR="$HOME/programming/scripts/config_os"
CONFIG_FILE="$HOME_DIR/configs/config.json"
ENV_PATH=$(jq -r '.config.env' $CONFIG_FILE)

source $HOME_DIR/$ENV_PATH
source $HOME_DIR/install_delete_apps.sh
source $HOME_DIR/config_os.sh
source $HOME_DIR/config_apps.sh
source $HOME_DIR/download.sh
source $HOME_DIR/other.sh

main() {
	delete
	delete_libreoffice
	install
	install_flatpak
	install_deb
	install_backend_tools

	configure_themes_and_icons
	configure_hotkeys
	configure_dock_panel
	configure_pop_cosmic
	configure_interface
	configure_night_light
	configure_screensaver
	configure_power
	configure_privacy
	configure_aliases
	configure_favorite_apps
	configure_default_apps
	configure_other

	configure_megacmd
	configure_zsh
	configure_kitty
	configure_tmux
	configure_git
	configure_nautilus
	configure_vscodium
	configure_keepassxc
	configure_gedit

	download_folders_from_mega
	download_notes

	create_venv_python
	remove_extra_files
	remove_config_files
}

if [ -n "$1" ]; then
	if [ "$(type -t "$1")" == "function" ]; then
        $1
    else
        echo "Функция $1 не найдена"
    fi
else
    main
fi