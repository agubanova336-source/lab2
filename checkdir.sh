#!/bin/bash

CREATE=0

# Парсинг аргументов командной строки
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c) CREATE=1; shift ;;
        -d) DIRNAME="$2"; shift 2 ;;
        -f) FILENAME="$2"; shift 2 ;;
        *) echo "Неизвестный параметр: $1"; exit 1 ;;
    esac
done

# Проверка наличия обязательных аргументов
if [[ -z "$DIRNAME" || -z "$FILENAME" ]]; then
    echo "Использование: $0 [-c] -d dirname -f filename"
    exit 1
fi

if [[ ! -d "$DIRNAME" ]]; then
    echo "Ошибка: Каталог '$DIRNAME' не существует."
    exit 1
fi

if [[ $CREATE -eq 1 ]]; then
    # Создание файла с эталонными хэш-суммами
    # find используется для рекурсивного обхода каталога
    find "$DIRNAME" -type f -exec md5sum {} + > "$FILENAME"
    echo "Файл с эталонными хэш-суммами '$FILENAME' успешно создан."
else
    # Режим проверки
    if [[ ! -f "$FILENAME" ]]; then
        echo "Ошибка: Файл с хэшами '$FILENAME' не найден."
        exit 1
    fi

    echo "=== Проверка измененных файлов (md5sum) ==="
    # Опция --quiet скрывает файлы с совпавшим хэшем, оставляя только ошибки (измененные файлы)
    md5sum -c "$FILENAME" --quiet

    echo "=== Проверка удаленных файлов ==="
    # Извлекаем пути файлов из эталонного списка и проверяем их наличие на диске
    sed 's/^[0-9a-f]* [ \*]//' "$FILENAME" | while read -r file; do
        if [[ ! -f "$file" ]]; then
            echo "УДАЛЕН: $file"
        fi
    done

    echo "=== Проверка новых файлов ==="
    # Обходим текущий каталог и ищем файлы, которых нет в эталонном списке
    find "$DIRNAME" -type f | while read -r file; do
        if ! grep -qF "$file" "$FILENAME"; then
            # Игнорируем сам файл с хэшами, если он сохранен внутри проверяемой директории
            if [[ "$(realpath "$file")" != "$(realpath "$FILENAME")" ]]; then
                echo "НОВЫЙ ФАЙЛ: $file"
            fi
        fi
    done
fi