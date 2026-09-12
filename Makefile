.PHONY:

PWD=$(shell pwd)

run:
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir

build:
	hugo --gc --minify

# Перезапуск dev-сервера с чисткой артефактов.
# Лечит "слетевшие стили"/ссылки на kgoryachev.ru в dev-режиме:
# случается, если параллельно с сервером запускалась обычная сборка `hugo`/`make build`
# (общие public/ и resources/_gen).
restart:
	pkill -f "hugo server" || true
	sleep 1
	rm -rf public resources/_gen
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir

chmod:
	chmod -R u+rwX,go+rX,go-w ./.