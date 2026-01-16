install:
	sudo apt-get install -yq  libasound2t64 libatk1.0-0 libc6 libcairo2 \
		libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 \
		libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 \
		libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
		libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
		libxss1 libxtst6 ca-certificates fonts-liberation libnss3 lsb-release \
		xdg-utils wget
	sudo npm install -g @dokploy/cli puppeteer
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
	sudo npm uninstall -g @dokploy/cli puppeteer