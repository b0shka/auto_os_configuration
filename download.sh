#! /bin/bash

download_folders_from_mega() {
	MEGA_BACKUP_NAME=$(jq -r '.mega.backup_name' $CONFIG_FILE)
	MEGA_BACKUP_NAME_CRYPT=$(jq -r '.mega.backup_name_crypt' $CONFIG_FILE)
	KEY_PASS=$(jq -r '.config.key_pass' $CONFIG_FILE)

	mega-get /$MEGA_BACKUP_NAME_CRYPT $HOME
	openssl enc -aes-256-cbc -d -in $HOME/$MEGA_BACKUP_NAME_CRYPT -out $HOME/$MEGA_BACKUP_NAME -pass file:$HOME/$KEY_PASS
	tar xf $HOME/$MEGA_BACKUP_NAME -C $HOME
	
	rm $HOME/$MEGA_BACKUP_NAME
	rm $HOME/$MEGA_BACKUP_NAME_CRYPT
}

download_notes() {
	NOTES_PATH=$(jq -r '.paths.notes' $CONFIG_FILE)
	NOTES_GIT_LINK=$(jq -r '.other.notes_git_link' $CONFIG_FILE)

	mkdir $HOME/$NOTES_PATH
	git clone $NOTES_GIT_LINK $HOME/$NOTES_PATH
}