DESTDIR=/var/www/html/blog

all: build

update:
	git pull
	git submodule update --remote --merge
setup:

build: setup
	hugo

setup:
	git submodule init

clean:
	rm -fr public/
	mkdir public

install: build
	rsync -auv public/ ${DESTDIR}
	
serve:
	hugo server -D