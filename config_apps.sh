#! /bin/bash

configure_megacmd() {
    mega-login $MEGA_LOGIN $MEGA_PASSWORD

	EXCLUDE_FOLDERS=$(jq -r '.mega.exclude_folders[]' $CONFIG_FILE)
	mega-exclude -d Thumbs.db desktop.ini ~* ".*"
	mega-exclude -a $EXCLUDE_FOLDERS
}

configure_kitty() {
	KITTY_PATH=$(jq -r '.config.kitty' $CONFIG_FILE)
	sudo mkdir $HOME/.config/kitty
	sudo chmod 777 $HOME/.config/kitty
	cp $KITTY_PATH $HOME/.config/kitty/
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

configure_vscodium() {
	VSCODIUM_EXTENSIONS=$(jq -r '.vscodium.extensions[]' $CONFIG_FILE)
	for i in ${VSCODIUM_EXTENSIONS[@]}; do
	  	codium --install-extension $i
	done

	VSCODIUM_SETTINGS_PATH=$(jq -r '.config.vscodium.settings' $CONFIG_FILE)
	VSCODIUM_KEYBINDINGS_PATH=$(jq -r '.config.vscodium.keybindings' $CONFIG_FILE)

	cp $VSCODIUM_SETTINGS_PATH "$HOME/.config/VSCodium/User/"
	cp $VSCODIUM_KEYBINDINGS_PATH "$HOME/.config/VSCodium/User/"
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

	create_tmux_sessions
}

create_tmux_sessions() {
  	TMUX_SESSIONS=$(jq -r '.tmux.sessions' $CONFIG_FILE)
	tmux_session_keys=$(echo $TMUX_SESSIONS | jq -r 'keys[]')

	for session_key in $tmux_session_keys; do
		WINDOWS=$(jq -r ".tmux.sessions.$session_key" $CONFIG_FILE)
		window_keys=$(echo $WINDOWS | jq -r 'keys[]')
		tmux new-session -d -s $session_key

		for window_key in $window_keys; do
			# window_values=$(echo $WINDOWS | jq -r ".[\"$window_key\"]")
			tmux new-window -t $session_key: -n $window_key

			jq -r ".tmux.sessions.$session_key.$window_key[]" $CONFIG_FILE | while IFS= read -r command; do
				tmux send-keys -t $session_key:$window_key "$command" C-m
			done
		
			tmux send-keys -t $session_key:$window_key "clear" C-m

			if tmux list-windows -t $session_key | grep -q "zsh"; then
				tmux kill-window -t "$session_key:zsh"
			fi
		done
	done
}