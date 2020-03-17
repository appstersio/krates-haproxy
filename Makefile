# README: http://makefiletutorial.com

# Courtesy of: https://stackoverflow.com/a/49524393/3072002
# Common env variables (https://www.gnu.org/software/make/manual/make.html#index-_002eEXPORT_005fALL_005fVARIABLES)
.EXPORT_ALL_VARIABLES:

.PHONY: test build wipe run

build:
	@docker build --no-cache -t krates/haproxy:latest .

run:
	@docker run -it --rm -e "PRY_SESSION=1" -v "$$(pwd):/app" krates/haproxy

test:
	@docker run -it --rm -v "$$(pwd):/app" krates/haproxy rspec spec/

wipe:
	@docker ps -aq | xargs -r docker rm -f > /dev/null