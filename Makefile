HOST = $(shell hostname)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
TEMPDIR := $(shell mktemp -d -t dsrg_deploy.XXXXXX)

build:
	bundle install
	bundle exec jekyll build

preview:
	bundle install
	bundle exec jekyll serve --watch

deploy: build
	mv vendor $(TEMPDIR)/vendor
	mv _site $(TEMPDIR)/_site
	touch ensure-stash-stashes
	git stash --include-untracked
	git checkout gh-pages
	rm -rf *
	rm -rf .sass-cache .gitignore .lvimrc
	mv $(TEMPDIR)/_site/* .
	rm -rf $(TEMPDIR)/_site
	git add .
	git commit -am "Deploy by $(USER)@$(HOST)"
	git checkout $(BRANCH)
	git stash pop
	rm ensure-stash-stashes
	mv $(TEMPDIR)/vendor vendor
	rmdir $(TEMPDIR)
