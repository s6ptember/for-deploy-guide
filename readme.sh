# Для привязки к гитхабу по ssh
```
ssh-keygen -t ed25519 -C "your_email@example.com"
```

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

```
cat ~/.ssh/id_ed25519.pub
```



# команды для установки докера и зависимостей
```
sudo apt-get update

sudo apt-get install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```

```
sudo usermod -aG docker $USER

newgrp docker
```

```
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

```
sudo chmod +x /usr/local/bin/docker-compose
```

```
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx
```


# Настройка env на сервере
```
SECRET_KEY='django-insecure-j-1yji9f8sncumd=+px(c=i+&)9ww3un+vx=6tyn11_ge%^xb!'
POSTGRES_DB=name
POSTGRES_USER=name
POSTGRES_PASSWORD=name
POSTGRES_HOST=db
POSTGRES_PORT=5432

```



# Для получения сертификата:

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

```
sudo certbot --nginx -d domen.com -d www.domen.com
```

```
docker-compose stop nginx
```

```
sudo systemctl stop nginx
```


# Меняем после получения сертификатов:

```
events {}

http {
    include /etc/nginx/mime.types;
    server_tokens off;
    client_max_body_size 10M;

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

# Ограничение на 10 МБ
это в settings.py
```
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10 МБ (в байтах)
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10 МБ (в байтах)
```

```
docker-compose up --build -d
```

для статики
```
docker-compose exec web python manage.py collectstatic --noinput
```

для суперюзера
```
docker-compose exec web python manage.py createsuperuser
```

