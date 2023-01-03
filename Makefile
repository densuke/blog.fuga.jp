DESTDIR=/var/www/html/blog

all: install

build:
	bundle exec jekyll b

install: build
	rsync -auv _site/ $(DESTDIR)
