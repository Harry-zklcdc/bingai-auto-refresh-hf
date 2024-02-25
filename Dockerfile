FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git
WORKDIR /workspace
RUN git clone https://github.com/Harry-zklcdc/go-proxy-bingai.git && \
    cd go-proxy-bingai && \
    go build -o go-proxy-bingai

FROM ubuntu:latest

ENV USER ${USER:-user}
ENV USER_ID ${USER_ID:-1000}

WORKDIR /app

USER root

RUN apt-get update && apt-get install -y --no-install-recommends curl supervisor python3 python3-pip

RUN pip install Flask

RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared && \
    chmod +x cloudflared

RUN apt-get remove -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /workspace/go-proxy-bingai/go-proxy-bingai /app/go-proxy-bingai
COPY app.py /app/app.py
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN groupadd -g $USER_ID $USER
RUN useradd -rm -G sudo -u $USER_ID -g $USER_ID $USER

RUN mkdir -p /var/run/supervisor /var/log/supervisor
RUN chown "${USER_ID}:${USER_ID}" /var/run/supervisor /var/log/supervisor

USER $USER

ENV PORT=45678
ENV LOCAL_MODE=true

EXPOSE 7860

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf