install:
	npm install -g @dokploy/cli
	sudo ./scripts/install-dokploy.sh install_dokploy

update:
	./scripts/install-dokploy.sh update_dokploy

start:
	sudo ./scripts/start-dokploy.sh

stop: 
	sudo ./scripts/stop-dokploy.sh

setup:
	sudo ./scripts/setup-dokploy.sh

uninstall:
	sudo ./scripts/uninstall-dokploy.sh