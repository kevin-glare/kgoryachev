.PHONY: news-publish

PWD=$(shell pwd)

run:
	hugo server --ignoreCache --disableFastRender --cleanDestinationDir

# Локальная сборка без Метрики: окружение development (в отличие от прода в CI,
# где HUGO_ENVIRONMENT=production). Прод-сборку локально: make build-prod.
build:
	hugo --gc --minify --environment development

build-prod:
	hugo --gc --minify --environment production

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
	chmod -R u+rwX,go+rX,go-w ./

# Публикация отревьюенного черновика выпуска новостей. Черновик лежит прямо
# в content/news/ с draft: true — Hugo его не рендерит. Публикация = снять
# флаг и проверить сборку. Пуш в git и отправку в Telegram делает владелец
# вручную (TG-сообщение генерируется из того же markdown).
# Пример: make news-publish DATE=2026-10-12
news-publish:
	@test -n "$(DATE)" || (echo "usage: make news-publish DATE=YYYY-MM-DD"; exit 1)
	@test -f content/news/$(DATE).md || (echo "нет черновика content/news/$(DATE).md"; exit 1)
	@grep -q '^draft: true' content/news/$(DATE).md || (echo "в content/news/$(DATE).md нет draft: true — выпуск уже опубликован?"; exit 1)
	perl -pi -e 's/^draft: true$$/draft: false/' content/news/$(DATE).md
	$(MAKE) build
	@echo ""
	@echo "Черновик опубликован в сборке: content/news/$(DATE).md (draft: false). Дальше вручную:"
	@echo "  git add content/news && git commit -m 'news: дайджест $(DATE)' && git push"
	@echo "  scripts/tg_send.sh content/news/$(DATE).md".