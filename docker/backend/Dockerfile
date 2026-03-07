FROM python:3.13-slim

# System dependencies for PostGIS, Pillow, and gettext (for i18n)
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    binutils \
    libpq-dev \
    libjpeg-dev \
    zlib1g-dev \
    libwebp-dev \
    gettext \
    && rm -rf /var/lib/apt/lists/*

# Set GDAL environment variables required by GeoDjango
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY backend/ .

EXPOSE 8000