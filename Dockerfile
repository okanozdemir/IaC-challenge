FROM alpine:3.14.2 as base

FROM base as builder

RUN apk add --no-cache \
       gcc \
       python3-dev \
       musl-dev \
       mariadb-dev \
       py3-pip

RUN mkdir /install
WORKDIR /install

RUN pip install --prefix=/install flask mysqlclient

FROM base

RUN apk add --no-cache \
       python3 \
       py3-gunicorn

COPY --from=builder /install /usr/

RUN mkdir /app
COPY app.py /app
WORKDIR /app

CMD ["gunicorn", "app"]
