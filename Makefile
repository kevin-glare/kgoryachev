.PHONY:

PWD=$(shell pwd)

run:
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir

build:
	hugo --gc --minify

deploy:
	scp -r ./public/* server:~/personal/

chmod: 
	chmod -R u+rwX,go+rX,go-w ./.