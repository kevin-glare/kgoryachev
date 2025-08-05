.PHONY:

PWD=$(shell pwd)

run:
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir

build:
	hugo --gc --minify

chmod: 
	chmod -R u+rwX,go+rX,go-w ./.