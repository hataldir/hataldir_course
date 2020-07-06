FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

RUN apk --no-cache --update add build-base gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del build-base

ENV EXCLUDE_URLS '.*github.com'

ENTRYPOINT ["python3", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site"]
