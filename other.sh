#! /bin/bash

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