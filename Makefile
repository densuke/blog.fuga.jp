all: build

update:
	bundle update
	git add Gemfile.lock && git commit -m "[etc][AUTO] bundle updated" Gemfile.lock

setup:
	bundle install

build: setup
	bundle exec jekyll b

serve: setup
	bundle exec jekyll serve

clean:
	bundle exec jekull clean


