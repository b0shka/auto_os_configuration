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

configure_dock_panel() {
	DOCK_SETTINGS=$(jq -r '.os.dock' $CONFIG_FILE)
	keys=$(echo $DOCK_SETTINGS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $DOCK_SETTINGS | jq -r ".$key")
		gsettings set org.gnome.shell.extensions.dash-to-dock $key $value
	done
}

configure_pop_cosmic() {
	POP_COSMIC_SETTINGS=$(jq -r '.os.pop-cosmic' $CONFIG_FILE)
	keys=$(echo $POP_COSMIC_SETTINGS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $POP_COSMIC_SETTINGS | jq -r ".$key")
		gsettings set org.gnome.shell.extensions.pop-cosmic $key $value
	done
}

configure_other() {
	gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
	gsettings set org.gnome.desktop.interface clock-show-date true
	gsettings set org.gnome.desktop.interface enable-hot-corners false
	gsettings set org.gnome.desktop.interface show-battery-percentage true
	gsettings set org.gnome.desktop.interface enable-animations true
	gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,close'

	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 21.0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 8.0

	gsettings set org.gnome.desktop.interface clock-format '24h'

	gsettings set org.gnome.desktop.datetime automatic-timezone true
	timedatectl set-timezone Asia/Yekaterinburg

	# задержка выключения экрана
	gsettings set org.gnome.desktop.session idle-delay 0

	# автоматическая блокировка экрана
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	# задержка автоматической блокировки экрана
	gsettings set org.gnome.desktop.screensaver lock-delay 1500
	# блокировка экрана в режиме ожидания
	gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend true

	# история файлов
	gsettings set org.gnome.desktop.privacy remember-recent-files false
	# автоматически удалять файлы в корзине
	gsettings set org.gnome.desktop.privacy remove-old-trash-files false
	# автоматически удалять временные файлы
	gsettings set org.gnome.desktop.privacy remove-old-temp-files false
	# действие для кнопки выключения
	gsettings set org.gnome.settings-daemon.plugins.power power-button-action nothing

	# Отключить автоматическую систему ожидания
	gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
	gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
}

configure_aliases() {
	ALIASES=$(jq -r '.aliases' $CONFIG_FILE)
	keys=$(echo $ALIASES | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $ALIASES | jq -r ".$key")
		echo "alias $key='$value'" >> ~/.bashrc
	done
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

configure_nautilus() {
	gsettings set org.gnome.nautilus.preferences default-folder-viewer list-view
	gsettings set org.gnome.nautilus.list-view default-zoom-level small

	gsettings set org.gnome.nautilus.preferences show-hidden-files false
	gsettings set org.gnome.nautilus.preferences click-policy double
	gsettings set org.gnome.nautilus.compression default-compression-format tar.xz

	gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size']"
}

configure_vscode() {
	VSCODE_PATH=$(jq -r '.config.vscode' $CONFIG_FILE)
	cp $VSCODE_PATH "$HOME/.config/Code/User/settings.json"

	VSCODE_EXTENSIONS=$(jq -r '.vscode.extensions[]' $CONFIG_FILE)
	for i in ${VSCODE_EXTENSIONS[@]}; do
	  	code --install-extension $i
	done
}


### DOWNLOAD

download_folders_from_mega() {
	MEGA_DOWNLOAD_FOLDERS=$(jq -r '.mega.download_folders[]' $CONFIG_FILE)

	for i in ${MEGA_DOWNLOAD_FOLDERS[@]}; do
	  	mega-get /$i $HOME
	done
}

download_notes() {
	NOTES_PATH=$(jq -r '.paths.notes' $CONFIG_FILE)

	mkdir $HOME/$NOTES_PATH
	git clone $NOTES_GIT_LINK $HOME/$NOTES_PATH
}


### OTHER

create_venv_python() {
	VENV_PATH=$(jq -r '.paths.venv' $CONFIG_FILE)
	python3 -m venv $HOME/$VENV_PATH
}


main() {
	# delete
	# install
	# install_flatpak
	# install_golang

	# configure_themes_and_icons
	# configure_hotkeys
	# configure_dock_panel
	# configure_pop_cosmic
	# configure_other
	# configure_aliases

	# configure_megacmd
	# configure_alacritty
	# configure_git
	# configure_nautilus
	# configure_vscode

	# download_folders_from_mega
	# download_notes

	# create_venv_python
}

main