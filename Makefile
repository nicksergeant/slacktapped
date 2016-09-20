deploy:
	git push dokku

docs:
	mix docs --main="readme"
	rm -rf ../slacktapped-docs/dist
	rm -rf ../slacktapped-docs/fonts
	mv doc/* ../slacktapped-docs/
	cd ../slacktapped-docs
	git add .
	git commit -m "Updating docs"
	git push
	cd ../slacktapped

.PHONY: deploy docs
