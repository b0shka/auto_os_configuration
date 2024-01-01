#! /bin/bash

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

install_deb() {
	LINKS_DOWNLOAD=$(jq -r '.apps.install_deb' $CONFIG_FILE)
	keys=$(echo $LINKS_DOWNLOAD | jq -r 'keys[]')

	for key in $keys; do
		value=$(echo $LINKS_DOWNLOAD | jq -r ".[\"$key\"]")
		wget $value -O $key.deb
		sudo chmod 777 $key.deb
		sudo dpkg -i $key.deb
		rm $key.deb
		sudo apt -f install -y
	done
}

install_backend_tools() {
	install_golang
	install_docker
	install_docker_containers
	install_tableplus

	TOOLS_BACKEND=$(jq -r '.apps.backend.tools[]' $CONFIG_FILE)

	for i in ${TOOLS_BACKEND[@]}; do
	  	go install $i
	done
}

install_golang() {
	VERSION_GOLANG=$(jq -r '.apps.backend.versions.golang' $CONFIG_FILE)
	wget https://go.dev/dl/go$VERSION_GOLANG.linux-amd64.tar.gz
	sudo rm -rf /usr/local/go
	sudo tar -C /usr/local -xzf go$VERSION_GOLANG.linux-amd64.tar.gz

	echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
}

install_docker() {
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg -y

	sudo install -m 0755 -d /etc/apt/keyrings -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg

	echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

	# sudo groupadd docker
	# sudo usermod -aG docker $USER
	# newgrp docker
	sudo chmod 666 /var/run/docker.sock
}

install_docker_containers() {
	CONTAINERS=$(jq -r '.apps.docker_containers[]' $CONFIG_FILE)

	for i in ${CONTAINERS[@]}; do
	  	docker pull $i
	done
}

install_tableplus() {
	wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null

	sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"

	sudo apt update
	sudo apt install tableplus -y
}
