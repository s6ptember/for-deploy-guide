# Руководство по деплою проектов

Это руководство описывает процесс настройки SSH-доступа к GitHub, установки Docker и зависимостей, настройки окружения, получения SSL-сертификатов и деплоя проекта с использованием Docker Compose и Nginx. Видео: https://youtu.be/MORz2S5Bm0A?si=OkiFpouUtF8W09Hl

---

## 1. Настройка SSH-доступа к GitHub

Для безопасной работы с репозиториями на GitHub настройте SSH-ключи.

### Шаги:
1. **Генерация SSH-ключа**  
   Выполните команду для создания нового ключа. Замените `your_email@example.com` на ваш email.
   ```
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Запуск SSH-агента и добавление ключа**  
   Запустите SSH-агент и добавьте ваш приватный ключ.
   ```
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Копирование публичного ключа**  
   Выведите публичный ключ и скопируйте его в настройки GitHub (раздел SSH and GPG keys).
   ```
   cat ~/.ssh/id_ed25519.pub
   ```

---

## 2. Установка Docker и зависимостей

Для работы проекта на сервере установите Docker, Docker Compose и Nginx.

### Установка Docker
1. **Обновление системы и установка зависимостей**  
   ```
   sudo apt-get update
   sudo apt-get install ca-certificates curl
   ```

2. **Добавление ключей и репозитория Docker**  
   ```
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```

3. **Установка Docker и его компонентов**  
   ```
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

4. **Добавление текущего пользователя в группу Docker**  
   Это позволит запускать Docker-команды без `sudo`.
   ```
   sudo usermod -aG docker $USER
   newgrp docker
   ```

### Установка Docker Compose
1. **Скачивание и установка Docker Compose**  
   ```
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

### Установка Nginx и Certbot
1. **Установка Nginx и инструментов для получения SSL-сертификатов**  
   ```
   sudo apt update
   sudo apt install nginx certbot python3-certbot-nginx
   ```

---

## 3. Настройка переменных окружения

Создайте файл `.env` на сервере с переменными окружения для вашего проекта. Пример:

```
SECRET_KEY='django-insecure-j-1yji9f8sncumd=+px(c=i+&)9ww3un+vx=6tyn11_ge%^xb!'
POSTGRES_DB=name
POSTGRES_USER=name
POSTGRES_PASSWORD=name
POSTGRES_HOST=db
POSTGRES_PORT=5432
```

> **Примечание**: Замените значения на ваши собственные. Храните файл `.env` в безопасном месте и не добавляйте его в репозиторий.

---

## 4. Настройка Nginx и получение SSL-сертификатов

Для работы сайта настройте Nginx и получите SSL-сертификаты через Certbot.

### Настройка Nginx до получения сертификатов
Создайте конфигурационный файл Nginx со следующим содержимым:

```
events {}

http {
    server {
        listen 80;
        server_name domen.com www.domen.com;

        location / {
            proxy_pass http://web:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            alias /app/static/;
        }

        location /media/ {
            alias /app/media/;
        }
    }
}
```

> **Замените** `domen.com` на ваш домен.

### Получение SSL-сертификатов
1. **Запуск Certbot для автоматической настройки HTTPS**  
   ```
   sudo certbot --nginx -d domen.com -d www.domen.com
   ```

2. **Остановка сервисов Nginx**  
   После получения сертификатов остановите Nginx-контейнер и системный Nginx:
   ```
   docker-compose stop nginx
   sudo systemctl stop nginx
   ```

### Обновление конфигурации Nginx после получения сертификатов
После получения сертификатов обновите файл `nginx.conf`:

```
events {}

http {
    include /etc/nginx/mime.types;
    server_tokens off;
    client_max_body_size 10M;

    upstream django {
        server web:8000;
    }

    server {
        listen 80;
        server_name domen.com www.domen.com;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name domen.com www.domen.com;

        ssl_certificate /etc/letsencrypt/live/domen.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/domen.com/privkey.pem;

        location / {
            proxy_pass http://django;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            alias /app/static/;
        }

        location /media/ {
            alias /app/media/;
        }
    }
}
```

> **Замените** `domen.com` на ваш домен.

---

## 5. Настройка Django

### Ограничение размера загружаемых файлов
В файле `settings.py` вашего Django-проекта добавьте следующие строки для ограничения размера загружаемых файлов до 10 МБ:

```
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10 МБ (в байтах)
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10 МБ (в байтах)
```

---

## 6. Деплой проекта

### Сборка и запуск контейнеров
1. **Запуск проекта с помощью Docker Compose**  
   ```
   docker-compose up --build -d
   ```

2. **Сбор статических файлов**  
   Выполните команду для сбора статических файлов Django:
   ```
   docker-compose exec web python manage.py collectstatic --noinput
   ```

3. **Создание суперпользователя**  
   Создайте администратора для доступа к админ-панели Django:
   ```
   docker-compose exec web python manage.py createsuperuser
   ```

---

## 7. Полезные команды

- **Перезапуск контейнеров**:
  ```
  docker-compose down && docker-compose up --build -d
  ```

- **Проверка логов**:
  ```
  docker-compose logs
  ```

- **Остановка всех контейнеров**:
  ```
  docker-compose down
  ```

---

## 8. Примечания

- Убедитесь, что ваш домен (`domen.com`) указан правильно во всех конфигурациях.
- Регулярно обновляйте SSL-сертификаты с помощью `certbot renew`.
- Храните файл `.env` в безопасном месте и не коммитьте его в репозиторий.
- Если возникают ошибки, проверьте логи Docker (`docker-compose logs`) или Nginx (`/var/log/nginx/error.log`).
- Не забудьте привязать dns адреса домена к серверу.

---

*Создано для упрощения деплоя ваших проектов!*