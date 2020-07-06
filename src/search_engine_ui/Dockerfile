FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

RUN apk --no-cache --update add build-base gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del build-base

ENV EXCLUDE_URLS '.*github.com'

CMD cd ui && FLASK_APP=ui.py gunicorn ui:app -b 0.0.0.0
