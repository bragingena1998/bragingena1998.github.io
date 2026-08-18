#!/bin/bash
# Выложить сайт сразу в оба места: свой сервер и GitHub Pages.
#
# Запуск из папки site:
#   bash "Выложить сайт.sh" "что изменилось"
#
# Зачем два места — см. «Выложить сайт.md». Коротко: главный адрес свой,
# а github остаётся зеркалом, пока в рекламной кампании прописан он.
#
# Скрипт останавливается на первой же ошибке: половина выложенного хуже,
# чем невыложенное — расхождение между зеркалами заметить некому.
set -e

SERVER="root@85.198.96.149"
REMOTE="/var/www/sobez-site"
MAIN="https://sobez.mindandmotion.ru"
MIRROR="https://bragingena1998.github.io"
PAGES="index.html offer.html terms.html privacy.html oplacheno.html"

MESSAGE="${1:-Обновление сайта}"

cd "$(dirname "$0")"

echo "--- на свой сервер ---"
for page in $PAGES; do
    scp -q "$page" "$SERVER:$REMOTE/$page"
    echo "  $page"
done
ssh "$SERVER" "chown -R www-data:www-data $REMOTE"

echo
echo "--- в GitHub ---"
git add -A
if git diff --cached --quiet; then
    echo "  нечего отправлять, файлы не менялись"
else
    git commit -q -m "$MESSAGE"
    git push -q
    echo "  отправлено: $MESSAGE"
fi

echo
echo "--- проверка ---"
bad=0
for host in "$MAIN" "$MIRROR"; do
    for page in "" "/offer.html" "/terms.html" "/privacy.html"; do
        # Случайный хвост в адресе — чтобы не смотреть в кэш вместо страницы.
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 \
               "$host/$page?v=$RANDOM")
        if [ "$code" != "200" ]; then
            echo "  ПЛОХО $host/$page -> $code"
            bad=1
        fi
    done
    echo "  $host — все страницы отвечают"
done

if [ "$bad" != "0" ]; then
    echo
    echo "⚠️ Что-то не отдаётся. GitHub Pages обновляется до минуты —"
    echo "   если плохо только зеркало, подождите и проверьте ещё раз."
    exit 1
fi

echo
echo "Готово. Главный адрес: $MAIN"
