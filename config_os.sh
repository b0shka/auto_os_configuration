#! /bin/bash

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