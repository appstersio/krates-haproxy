# README: http://makefiletutorial.com
LE_DOMAINS=$(shell bash -c "cat tmp/env | grep -o -P '(?<=LE_DOMAINS=).*'")
LE_EMAIL=$(shell bash -c "cat tmp/env | grep -o -P '(?<=LE_EMAIL=).*'")
FRPS_ENDPOINT=$(shell bash -c "cat tmp/env | grep -o -P '(?<=FRPS_ENDPOINT=).*'")
FRPS_TOKEN=$(shell bash -c "cat tmp/env | grep -o -P '(?<=FRPS_TOKEN=).*'")

.PHONY: test build wipe run sslscan tunnel

# Configures your environment with temporary settings
env:
	@read -p "frp is running: " ok;
	@read -p "LE_DOMAINS: " value; echo LE_DOMAINS=$$value > tmp/env
	@read -p "LE_EMAIL: " value; echo LE_EMAIL=$$value >> tmp/env
	@read -p "FRPS_ENDPOINT: " value; echo FRPS_ENDPOINT=$$value >> tmp/env
	@read -p "FRPS_TOKEN: " value; echo FRPS_TOKEN=$$value >> tmp/env
# Builds latest image
build:
	@docker build --no-cache -t krates/haproxy:latest .
# Runs HAProxy container in pry-session mode for debugging and troubleshooting purposes
debug:
	@docker run -d --rm -p 9292:4000 --name kontena-server-api staticpagesio/oxy:0.1.11
	@docker run -it --rm -p 80:80 -p 443:443 --link kontena-server-api:kontena-server-api -e "LE_DOMAINS=$(LE_DOMAINS)" -e "LE_EMAIL=$(LE_EMAIL)" -e "PRY_SESSION=1" -v "$$(pwd):/app" -v "$$(pwd)/tmp/ssl:/etc/ssl/private" -v "$$(pwd)/tmp/acme:/var/lib/acme" krates/haproxy
# Configures and runs all prerequisites to validate HAProxy and LetsEncrypt
run: wipe tunnel debug
# Runs sslscan from toolbox to evaluate whether LetsEncrypt integration works as expected
sslscan:
	@docker run -ti --rm --net host krates/toolbox:2.7.0-1 -c "sslscan --http --sni-name=$(LE_DOMAINS) 0.0.0.0:443"
# Establishes a tunnel so that LetsEncrypt can reach out to acme worker in HAProxy container
tunnel: wipe
	@docker run -d --rm --log-driver journald --name frpc --net host krates/frp sh -c "frpc http -s $(FRPS_ENDPOINT) -l 80 -t $(FRPS_TOKEN) -d $(LE_DOMAINS)"
	@sleep 5 && docker logs frpc
# Simply runs RSpec
test:
	@docker run -it --rm -v "$$(pwd):/app" krates/haproxy rspec spec/
# Wipes out all the containers running
wipe:
	@docker ps -aq | xargs -r docker rm -f > /dev/null