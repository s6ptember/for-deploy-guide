FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    gettext \  
    vim \
    && rm -rf /var/lib/apt/lists/*
    
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["sh", "-c", "python manage.py migrate && gunicorn projectname.wsgi:application --bind 0.0.0.0:8000"]