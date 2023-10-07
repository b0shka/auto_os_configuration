#! /bin/bash

sudo apt-get install jq -y
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

delete_libreoffice() {
	sudo apt-get remove --purge libreoffice* -y
	sudo apt-get clean -y
	sudo apt-get autoremove -y

	# rm -r ~/.config/libreoffice
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
	  	flatpak install flathub $i -y
	done
}

install_megacmd() {
	MEGA_LINK_DOWNLOAD=$(jq -r '.mega.link_download' $CONFIG_FILE)
	wget $MEGA_LINK_DOWNLOAD

	MEGA_NAME_FILE=$(jq -r '.mega.name_file' $CONFIG_FILE)
	sudo chmod 777 $MEGA_NAME_FILE
	sudo dpkg -i $MEGA_NAME_FILE
	rm $MEGA_NAME_FILE
	sudo apt -f install -y
}

install_backend_tools() {
	install_golang
	install_docker
	install_docker_containers
	install_tableplus

	# sqlc
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

	# migrate
	go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	# VERSION_MIGRATE=$(jq -r '.apps.versions_backend_tools.migrate' $CONFIG_FILE)
	# curl -L https://github.com/golang-migrate/migrate/releases/download/$VERSION_MIGRATE/migrate.linux-amd64.tar.gz | tar xvz
	# sudo mv migrate /usr/bin/migrate

	# mockgen
	go install github.com/golang/mock/mockgen@latest

	# swag
	go install github.com/swaggo/swag/cmd/swag@latest

	# golangci-lint
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	# VERSION_GOLANGCI_LINT=$(jq -r '.apps.versions_backend_tools.golangci-lint' $CONFIG_FILE)
	# curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin $VERSION_GOLANGCI_LINT

	# other
	go install golang.org/x/tools/gopls@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/cweill/gotests/gotests@latest
	go install github.com/fatih/gomodifytags@latest
	go install github.com/go-delve/delve/cmd/dlv@latest
}

install_golang() {
	VERSION_GOLANG=$(jq -r '.apps.versions_backend_tools.golang' $CONFIG_FILE)
	wget https://go.dev/dl/go$VERSION_GOLANG.linux-amd64.tar.gz
	sudo rm -rf /usr/local/go
	sudo tar -C /usr/local -xzf go$VERSION_GOLANG.linux-amd64.tar.gz

	export PATH=$PATH:/usr/local/go/bin
	export PATH=$PATH:$HOME/go/bin
}

install_docker() {
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg

	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg

	echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	sudo groupadd docker
	sudo usermod -aG docker $USER
	newgrp docker
	sudo chmod 666 /var/run/docker.sock
}

install_docker_containers() {
	docker pull postgres:15-alpine
	docker pull redis:7-alpine
}

install_tableplus() {
	wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null

	sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"

	sudo apt update
	sudo apt install tableplus
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
	HOTKEYS=$(jq -r '.os.hotkeys' $CONFIG_FILE)
	keys=$(echo $HOTKEYS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $HOTKEYS | jq -r ".$key")
		gsettings set org.gnome.desktop.wm.keybindings $key $value
	done
}

configure_dock_panel() {
	DOCK_SETTINGS=$(jq -r '.os.dock' $CONFIG_FILE)
	keys=$(echo $DOCK_SETTINGS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo "$DOCK_SETTINGS" | jq -r ".[\"$key\"]")
		gsettings set org.gnome.shell.extensions.dash-to-dock $key $value
	done
}

configure_pop_cosmic() {
	POP_COSMIC_SETTINGS=$(jq -r '.os.pop_cosmic' $CONFIG_FILE)
	keys=$(echo $POP_COSMIC_SETTINGS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $POP_COSMIC_SETTINGS | jq -r ".[\"$key\"]")
		gsettings set org.gnome.shell.extensions.pop-cosmic $key $value
	done
}

configure_interface() {
	OS_INTERFACE=$(jq -r '.os.interface' $CONFIG_FILE)
	keys=$(echo $OS_INTERFACE | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $OS_INTERFACE | jq -r ".[\"$key\"]")
		gsettings set org.gnome.desktop.interface $key $value
	done
}

configure_night_light() {
	OS_NIGHT_LIGHT=$(jq -r '.os.night_light' $CONFIG_FILE)
	keys=$(echo $OS_NIGHT_LIGHT | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $OS_NIGHT_LIGHT | jq -r ".[\"$key\"]")
		gsettings set org.gnome.settings-daemon.plugins.color $key $value
	done
}

configure_screensaver() {
	# lock-enabled - автоматическая блокировка экрана
	# lock-delay - задержка автоматической блокировки экрана
	# ubuntu-lock-on-suspend - блокировка экрана в режиме ожидания

	OS_SCREENSAVER=$(jq -r '.os.screensaver' $CONFIG_FILE)
	keys=$(echo $OS_SCREENSAVER | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $OS_SCREENSAVER | jq -r ".[\"$key\"]")
		gsettings set org.gnome.desktop.screensaver $key $value
	done
}

configure_power() {
	OS_POWER=$(jq -r '.os.power' $CONFIG_FILE)
	keys=$(echo $OS_POWER | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $OS_POWER | jq -r ".[\"$key\"]")
		gsettings set org.gnome.settings-daemon.plugins.power $key $value
	done
}

configure_privacy() {
	OS_PRIVACY=$(jq -r '.os.privacy' $CONFIG_FILE)
	keys=$(echo $OS_PRIVACY | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $OS_PRIVACY | jq -r ".[\"$key\"]")
		gsettings set org.gnome.desktop.privacy $key $value
	done
}

configure_aliases() {
	ALIASES=$(jq -r '.aliases' $CONFIG_FILE)
	keys=$(echo $ALIASES | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $ALIASES | jq -r ".[\"$key\"]")
		echo "alias $key='$value'" >> ~/.bashrc
		echo "alias $key='$value'" >> ~/.zshrc
	done
}

configure_favorite_apps() {
	# gsettings get org.gnome.shell favorite-apps
	gsettings set org.gnome.shell favorite-apps "[]"

	FAVORITE_APPS=$(jq -r '.apps.favorite[]' $CONFIG_FILE)

	apps_to_favorite=""
	for app in $FAVORITE_APPS; do
		apps_to_favorite+=" '$app',"
	done

	apps_to_favorite="${apps_to_favorite%,}"
	gsettings set org.gnome.shell favorite-apps "[$apps_to_favorite]"
}

configure_default_apps() {
	DEFAULT_APPS=$(jq -r '.apps.default' $CONFIG_FILE)
	keys=$(echo $DEFAULT_APPS | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $DEFAULT_APPS | jq -r ".[\"$key\"]")
		xdg-settings set $key $value
	done
}

configure_other() {
	OS_BUTTON_LAYOUT=$(jq -r '.os.button_layout' $CONFIG_FILE)
	gsettings set org.gnome.desktop.wm.preferences button-layout $OS_BUTTON_LAYOUT

	OS_SOUND_ABOVE=$(jq -r '.os.volume_above' $CONFIG_FILE)
	gsettings set org.gnome.desktop.sound allow-volume-above-100-percent $OS_SOUND_ABOVE

	OS_FIRST_DAY_WEEK=$(jq -r '.os.first_day_week' $CONFIG_FILE)
	# Установка первого дня недели (0 - воскресенье, 1 - понедельник и т.д.)
	gsettings set org.gnome.desktop.calendar first-day-of-week $OS_FIRST_DAY_WEEK

	OS_AUTO_TIMEZOME=$(jq -r '.os.automatic_timezone' $CONFIG_FILE)
	gsettings set org.gnome.desktop.datetime automatic-timezone $OS_AUTO_TIMEZOME

	OS_TIMEZOME=$(jq -r '.os.timezone' $CONFIG_FILE)
	timedatectl set-timezone $OS_TIMEZOME

	OS_KEYBOARD_LAYOUT=$(jq -r '.os.keyboard_layout' $CONFIG_FILE)
	gsettings set org.gnome.desktop.input-sources sources "$OS_KEYBOARD_LAYOUT"

	OS_SCREEN_SHUTDOWN_DELAY=$(jq -r '.os.screen_shutdown_delay' $CONFIG_FILE)
	# задержка выключения экрана
	gsettings set org.gnome.desktop.session idle-delay $OS_SCREEN_SHUTDOWN_DELAY

	sudo rm /usr/share/applications/io.elementary.appcenter-daemon.desktop
}


### CONFIGURE APPS

configure_megacmd() {
    mega-login $MEGA_LOGIN $MEGA_PASSWORD

	EXCLUDE_FOLDERS=$(jq -r '.mega.exclude_folders[]' $CONFIG_FILE)
	mega-exclude -d Thumbs.db desktop.ini ~* ".*"
	mega-exclude -a $EXCLUDE_FOLDERS
}

configure_alacritty() {
	ALACRITTY_PATH=$(jq -r '.config.alacritty' $CONFIG_FILE)
	sudo mkdir $HOME/.config/alacritty
	sudo chmod 777 $HOME/.config/alacritty
	cp $ALACRITTY_PATH $HOME/.config/alacritty/
}

configure_git() {
	git config --global user.name $GIT_LOGIN
	git config --global user.email $GIT_EMAIL
	git config --global core.editor code
	git config --global init.defaultBranch main

	GIT_KEY_PATH=$(jq -r '.config.ssh.git' $CONFIG_FILE)
	sudo chmod 600 $HOME/$GIT_KEY_PATH
	GIT_PUB_KEY_PATH=$(jq -r '.config.ssh.git_pub' $CONFIG_FILE)
	sudo chmod 644 $HOME/$GIT_PUB_KEY_PATH
}

configure_nautilus() {
	NAUTILUS_PREFERENCES=$(jq -r '.nautilus.preferences' $CONFIG_FILE)
	keys=$(echo $NAUTILUS_PREFERENCES | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $NAUTILUS_PREFERENCES | jq -r ".[\"$key\"]")
		gsettings set org.gnome.nautilus.preferences $key $value
	done

	NAUTILUS_LIST_VIEW=$(jq -r '.nautilus.list_view' $CONFIG_FILE)
	keys=$(echo $NAUTILUS_LIST_VIEW | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $NAUTILUS_LIST_VIEW | jq -r ".[\"$key\"]")
		gsettings set org.gnome.nautilus.list-view $key "$value"
	done

	NAUTILUS_COMPRESSION=$(jq -r '.nautilus.compression_format' $CONFIG_FILE)
	gsettings set org.gnome.nautilus.compression default-compression-format $NAUTILUS_COMPRESSION

	# FAVORITE_FOLDERS=$(jq -r '.nautilus.favorite_folders[]' $CONFIG_FILE)
	# for i in ${FAVORITE_FOLDERS[@]}; do
	  	
	# done
}

configure_vscode() {
	VSCODE_EXTENSIONS=$(jq -r '.vscode.extensions[]' $CONFIG_FILE)
	for i in ${VSCODE_EXTENSIONS[@]}; do
	  	code --install-extension $i
	done

	VSCODE_SETTINGS_PATH=$(jq -r '.config.vscode.settings' $CONFIG_FILE)
	VSCODE_KEYBINDINGS_PATH=$(jq -r '.config.vscode.keybindings' $CONFIG_FILE)

	cp $VSCODE_SETTINGS_PATH "$HOME/.config/Code/User/"
	cp $VSCODE_KEYBINDINGS_PATH "$HOME/.config/Code/User/"
}

configure_keepassxc() {
	KEEPASSXC_PATH=$(jq -r '.config.keepassxc' $CONFIG_FILE)
	sudo mkdir $HOME/.config/keepassxc
	sudo chmod 777 $HOME/.config/keepassxc
	cp $KEEPASSXC_PATH "$HOME/.config/keepassxc/"
}

configure_gedit() {
	GEDIT_EDITOR=$(jq -r '.gedit.editor' $CONFIG_FILE)
	keys=$(echo $GEDIT_EDITOR | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $GEDIT_EDITOR | jq -r ".[\"$key\"]")
		gsettings set org.gnome.gedit.preferences.editor $key $value
	done


	GEDIT_UI=$(jq -r '.gedit.ui' $CONFIG_FILE)
	keys=$(echo $GEDIT_UI | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $GEDIT_UI | jq -r ".[\"$key\"]")
		gsettings set org.gnome.gedit.preferences.ui $key $value
	done
}

configure_zsh() {
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	ZSH_THEME=$(jq -r '.zsh.theme' $CONFIG_FILE)
	sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"$ZSH_THEME\"/" ~/.zshrc

	ZSH_PLUGINS=$(jq -r '.zsh.plugins[]' $CONFIG_FILE)
	formatted_plugins=$(printf "%s " $ZSH_PLUGINS)
	sed -i "s/plugins=(git)/plugins=($formatted_plugins)/"  ~/.zshrc

	ZSH_PLUGINS_GIT=$(jq -r '.zsh.plugins_link_git' $CONFIG_FILE)
	keys=$(echo $ZSH_PLUGINS_GIT | jq -r 'keys[]')
	for key in $keys; do
		value=$(echo $ZSH_PLUGINS_GIT | jq -r ".[\"$key\"]")
		sudo git clone $value $ZSH_CUSTOM/plugins/$key
	done

	ZSH_NOTIFY_IGNORE=$(jq -r '.zsh.notify_ignore[]' $CONFIG_FILE)
	formatted_notify_ignore=$(printf '"%s" ' $ZSH_NOTIFY_IGNORE)
	echo "AUTO_NOTIFY_IGNORE+=($formatted_notify_ignore)" >> ~/.zshrc

	source ~/.zshrc
}

configure_tmux() {
	TMUX_PATH=$(jq -r '.config.tmux' $CONFIG_FILE)
	sudo mkdir $HOME/.config/tmux
	sudo chmod 777 $HOME/.config/tmux
	cp $TMUX_PATH $HOME/.config/tmux/tmux.conf
	tmux source $HOME/.config/tmux/tmux.conf

	# sudo mkdir $HOME/.tmux
	# sudo chmod 777 $HOME/.tmux
	git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
	~/.config/tmux/plugins/tpm/scripts/install_plugins.sh
}


### DOWNLOAD

download_folders_from_mega() {
	MEGA_BACKUP_NAME=$(jq -r '.mega.backup_name' $CONFIG_FILE)

	mega-get /$MEGA_BACKUP_NAME $HOME
	tar xf $HOME/$MEGA_BACKUP_NAME -C $HOME
	rm $HOME/$MEGA_BACKUP_NAME
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

remove_extra_files() {
	EXTRA_FILES=$(jq -r '.remove_files.extra[]' $CONFIG_FILE)

	for i in ${EXTRA_FILES[@]}; do
	  	sudo rm -r $HOME/$i
	done
}

remove_config_files() {
	CONFIG_FILES=$(jq -r '.remove_files.config[]' $CONFIG_FILE)

	for i in ${CONFIG_FILES[@]}; do
	  	sudo rm -r $HOME/$i
	done
}


main() {
	delete
	# delete_libreoffice
	install
	install_flatpak
	install_megacmd
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
	configure_zsh
	configure_tmux
	configure_other

	configure_megacmd
	configure_alacritty
	configure_git
	configure_nautilus
	configure_vscode
	configure_keepassxc
	configure_gedit

	download_folders_from_mega
	download_notes

	create_venv_python
	remove_extra_files
	remove_config_files
}

main