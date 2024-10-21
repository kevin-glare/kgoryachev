.PHONY:

PWD=$(shell pwd)

run:
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir
