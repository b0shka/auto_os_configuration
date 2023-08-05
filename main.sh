#! /bin/bash

CONFIG=$(cat config.json | jq '.')
ENV_PATH=$(echo $CONFIG | jq -r '.config.env')
VENV_PATH=$(echo $CONFIG | jq -r '.path.venv')

source $HOME/$ENV_PATH

delete() {
	APPS_DELETE=$(echo $CONFIG | jq -r '.apps.delete[]')

	for i in ${APPS_DELETE[@]}; do
	  	sudo apt-get remove $i -y
	done
}

install() {
	APPS_INSTALL=$(echo $CONFIG | jq -r '.apps.install[]')

	for i in ${APPS_INSTALL[@]}; do
	  	sudo apt-get install $i -y
	done
}

install_flatpak() {
	APPS_INSTALL_FLATPAK=$(echo $CONFIG | jq -r '.apps.install_flatpak[]')

	for i in ${APPS_INSTALL_FLATPAK[@]}; do
	  	flatpak install flathub $i
	done
}

# copy_ssh_keys() {
# 	SSH_PATH=$(echo $CONFIG | jq -r '.config.ssh')
# 	sudo mkdir $HOME/.ssh
# 	sudo chmod 777 $HOME/.ssh
# 	cp $HOME/$SSH_PATH/* $HOME/.ssh/
# }

copy_themes_and_icons() {
	THEMES_PATH=$(echo $CONFIG | jq -r '.config.themes')
	sudo mkdir $HOME/.themes
	sudo chmod 777 $HOME/.themes
	tar -C $HOME/.themes -xf $HOME/$THEMES_PATH

	ICONS_PATH=$(echo $CONFIG | jq -r '.config.icons')
	sudo mkdir $HOME/.icons
	sudo chmod 777 $HOME/.icons
	tar -C $HOME/.icons -xf $HOME/$ICONS_PATH
}

configure_megacmd() {
    mega-login $MEGA_LOGIN $MEGA_PASSWORD
}

configure_alacritty() {
	ALACRITTY_PATH=$(echo $CONFIG | jq -r '.config.alacritty')
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

download_folders_from_mega() {
	MEGA_DOWNLOAD_FOLDERS=$(echo $CONFIG | jq -r '.mega.download_folders[]')

	for i in ${MEGA_DOWNLOAD_FOLDERS[@]}; do
	  	mega-get /$i $HOME
	done
}

download_notes() {
	NOTES_PATH=$(echo $CONFIG | jq -r '.notes.path')
	NOTES_FOLDER=$(echo $CONFIG | jq -r '.notes.name')

	if test -d $HOME/$NOTES_PATH; then
		mkdir $HOME/$NOTES_PATH/$NOTES_FOLDER
		git clone $NOTES_GIT_LINK $HOME/$NOTES_PATH/$NOTES_FOLDER
	else
		echo "Directory $NOTES_PATH does not exist"
	fi
}

create_venv_python() {
	python3 -m venv $HOME/$VENV_PATH
}

add_alias() {
	BACKUP_SCRIPT_PATH=$(echo $CONFIG | jq -r '.path.backup_script')
	echo "alias backup='$HOME/$BACKUP_SCRIPT_PATH'" >> ~/.bashrc
	
	echo "alias env='source $VENV_PATH/bin/activate'" >> ~/.bashrc
}

main() {
	# delete
	# install
	# install_flatpak
	# download_yandex_browser
	# download_brave_browser
	# download_mongodb
	# download_jetbrains
	# copy_ssh_keys
	# copy_themes_and_icons
	# configure_megacmd
	# configure_alacritty
	# configure_git
	# download_folders_from_mega
	# download_notes
	# create_venv_python
	# add_alias
}

main