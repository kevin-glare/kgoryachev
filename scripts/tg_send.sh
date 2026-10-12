#!/usr/bin/env bash
#
# Отправка сообщения в Telegram-канал через Bot API.
#
# Использование:
#   scripts/tg_send.sh [--dry-run] <файл-с-сообщением>
#
# Два типа входных файлов:
#   *.txt — готовый текст; ссылки в формате [текст](URL) конвертируются
#           в HTML-теги, остальное уходит как есть;
#   *.md  — черновик выпуска новостей (markdown с YAML-фронтматтером, как в
#           content/news/). TG-сообщение собирается из него автоматически:
#           заголовок выпуска жирным (префикс «Дайджест №N:» отбрасывается),
#           заголовок каждого пункта — жирная кликабельная ссылка на источник,
#           под ним комментарий, в конце — ссылка на выпуск на сайте. Ссылки
#           на свои статьи (/posts/...) становятся абсолютными и попадают
#           в TG. Правится только markdown — TG-версия руками не пишется.
#
# Лимит Telegram — 4096 символов, скрипт проверяет.
#
# Настройки берутся из .env в корне репозитория (не коммитится) или из окружения:
#   TELEGRAM_BOT_TOKEN — токен бота от @BotFather
#   TELEGRAM_CHAT_ID   — идентификатор канала: @username или -100xxxxxxxxxx
#
# Чтобы бот мог постить в канал, добавьте его администратором канала.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
SITE_BASE_URL="https://kgoryachev.ru"
SITE_NEWS_URL="$SITE_BASE_URL/news"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "usage: scripts/tg_send.sh [--dry-run] <файл-с-сообщением>" >&2
  exit 1
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "ОШИБКА: не заданы TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID." >&2
  echo "Создайте .env в корне репозитория (образец — .env.example) или экспортируйте переменные." >&2
  exit 2
fi

if [[ "$(head -1 "$FILE")" == "---" ]]; then
  # Markdown-выпуск новостей: собираем TG-сообщение из одного источника.
  # Секция "### Заголовок" -> жирный заголовок, её текст -> комментарий,
  # последняя http(s)-ссылка -> строка "Источник:". Относительные ссылки
  # (/posts/...) становятся абсолютными — на сайт.
  DATE_SLUG="$(basename "$FILE" .md)"
  PREVIEW_URL="$SITE_NEWS_URL/$DATE_SLUG/"
  MESSAGE="$(awk -v site_url="$SITE_NEWS_URL" -v date_slug="$DATE_SLUG" '
    function trim(s) { sub(/^\n+/, "", s); sub(/\n+$/, "", s); return s }
    function flushitem() {
      if (heading == "") return
      if (match(link, /\((https?:\/\/[^)]+)\)/)) {
        url = substr(link, RSTART + 1, RLENGTH - 2)
        items = items "<b><a href=\"" url "\">" heading "</a></b>\n"
      } else {
        items = items "<b>" heading "</b>\n"
      }
      if (body != "") items = items trim(body)
      items = items "\v"
      heading = ""; body = ""; link = ""
    }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm == 1 && $0 == "---" { fm = 0; next }
    fm == 1 {
      if ($0 ~ /^title:/) {
        t = $0; sub(/^title:[ ]*"?/, "", t); sub(/"?$/, "", t); title = t
      }
      next
    }
    /^### / { flushitem(); h = $0; sub(/^### +/, "", h); heading = h; next }
    heading != "" {
      if (match($0, /\[[^]]+\]\(https?:\/\/[^)]+\)/)) {
        link = substr($0, RSTART, RLENGTH)
      } else {
        body = body $0 "\n"
      }
      next
    }
    { intro = intro $0 "\n" }
    END {
      flushitem()
      sub(/^Дайджест №[0-9]+:[ \t]*/, "", title)
      out = "<b>" title "</b>\n\n"
      intro = trim(intro)
      if (intro != "") out = out intro "\v"
      out = out items
      sub(/\v+$/, "", out)
      out = out "\v<b><a href=\"" site_url "/" date_slug "/\">Полный выпуск</a></b>"
      printf "%s", out
    }
  ' "$FILE")"
else
  MESSAGE="$(cat "$FILE")"
  PREVIEW_URL=""
fi

# Относительные ссылки ведём на сайт, [текст](url) -> <a href="url">текст</a>,
# **жирный** -> <b>, `код` -> без обратных кавычек.
MESSAGE="$(sed -E 's|\]\((/[^)]+)\)|]('"$SITE_BASE_URL"'\1)|g' <<<"$MESSAGE" \
  | sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g' \
  | sed -E 's/\*\*([^*]+)\*\*/<b>\1<\/b>/g' \
  | sed -E 's/`([^`]+)`/\1/g')"

# Telegram ограничивает сообщение 4096 символами: делим по границам пунктов
# (юниты размечены вертикальной табуляцией \v), «Полный выпуск» — последним.
sep=$'\v'
units=()
remainder="$MESSAGE"
while [[ -n "$remainder" ]]; do
  units+=("${remainder%%"$sep"*}")
  if [[ "$remainder" == *"$sep"* ]]; then
    remainder="${remainder#*"$sep"}"
  else
    remainder=""
  fi
done

CHUNKS=()
cur=""
for u in "${units[@]}"; do
  if [[ ${#u} -gt 4096 ]]; then
    echo "ОШИБКА: пункт длиннее 4096 символов — сократи его в $FILE:" >&2
    printf '%s\n' "${u:0:200}" >&2
    exit 3
  fi
  if [[ -n "$cur" && $(( ${#cur} + 2 + ${#u} )) -gt 4096 ]]; then
    CHUNKS+=("$cur")
    cur=""
  fi
  if [[ -n "$cur" ]]; then cur="$cur"$'\n\n'"$u"; else cur="$u"; fi
done
[[ -n "$cur" ]] && CHUNKS+=("$cur")

# Превью выпуска показываем, только если страница уже доступна на сайте:
# Telegram собирает превью в момент отправки и кэширует его. Если страницы
# нет — откатываемся к превью по первой ссылке текста.
PREVIEW_STATUS=""
if [[ -n "${PREVIEW_URL:-}" ]]; then
  http_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$PREVIEW_URL" || true)"
  if [[ "$http_code" == "200" ]]; then
    PREVIEW_STATUS="превью выпуска: $PREVIEW_URL"
  else
    PREVIEW_STATUS="ВНИМАНИЕ: $PREVIEW_URL недоступна (HTTP $http_code) — превью будет от первой ссылки. Опубликуйте выпуск на сайте (push + деплой) и отправьте снова."
    PREVIEW_URL=""
  fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "--- DRY RUN: получатель ${TELEGRAM_CHAT_ID}, частей: ${#CHUNKS[@]} ---"
  [[ -n "$PREVIEW_STATUS" ]] && echo "$PREVIEW_STATUS"
  for i in "${!CHUNKS[@]}"; do
    echo ""
    echo "--- часть $(( i + 1 ))/${#CHUNKS[@]} ---"
    printf '%s\n' "${CHUNKS[$i]}"
  done
  exit 0
fi

for i in "${!CHUNKS[@]}"; do
  [[ $i -gt 0 ]] && sleep 1
  # Первая часть: превью страницы выпуска (или от первой ссылки, если
  # страница недоступна). Остальные части — без превью.
  if [[ $i -eq 0 && -n "${PREVIEW_URL:-}" ]]; then
    preview_args=(--data-urlencode "link_preview_options={\"url\":\"${PREVIEW_URL}\"}")
  elif [[ $i -eq 0 ]]; then
    preview_args=(--data-urlencode "disable_web_page_preview=false")
  else
    preview_args=(--data-urlencode "disable_web_page_preview=true")
  fi
  RESPONSE="$(curl -sS --fail-with-body -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "parse_mode=HTML" \
    "${preview_args[@]}" \
    --data-urlencode "text=${CHUNKS[$i]}")"

  if grep -q '"ok":true' <<<"$RESPONSE"; then
    echo "Отправлена часть $(( i + 1 ))/${#CHUNKS[@]} в ${TELEGRAM_CHAT_ID}"
  else
    echo "ОШИБКА: Telegram ответил неуспехом (часть $(( i + 1 ))): $RESPONSE" >&2
    exit 4
  fi
done
