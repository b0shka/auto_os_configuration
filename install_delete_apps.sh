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
	CONTAINERS=$(jq -r '.apps.docker_containers[]' $CONFIG_FILE)

	for i in ${CONTAINERS[@]}; do
	  	docker pull $i -y
	done
}

install_tableplus() {
	wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null

	sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"

	sudo apt update
	sudo apt install tableplus
}
