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

RUN apt-get update && apt-get install -y --no-install-recommends curl supervisor python3 python3-pip wget gnupg2 ca-certificates

# Install xcfb
RUN apt-get install -y --no-install-recommends xvfb xauth pulseaudio

# Install locales
RUN apt-get install -y --no-install-recommends language-pack-en tzdata locales && \
    locale-gen en_US.UTF-8

# Install fluxbox
RUN apt-get install -y --no-install-recommends fluxbox eterm hsetroot feh

# Install Edge
RUN wget -q -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null \
    && echo "deb https://packages.microsoft.com/repos/edge stable main" >> /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install microsoft-edge-stable
COPY wrap_edge_binary /opt/bin/wrap_edge_binary
RUN /opt/bin/wrap_edge_binary

RUN curl -L https://github.com/Harry-zklcdc/go-bingai-pass/releases/latest/download/go-bingai-pass-linux-amd64.tar.gz -o go-bingai-pass-linux-amd64.tar.gz && \
    tar -zxvf go-bingai-pass-linux-amd64.tar.gz && \
    chmod +x go-bingai-pass

RUN pip install Flask

RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared && \
    chmod +x cloudflared

RUN apt-get remove -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm go-bingai-pass-linux-amd64.tar.gz

COPY --from=builder /workspace/go-proxy-bingai/go-proxy-bingai /app/go-proxy-bingai
COPY start-xvfb.sh /opt/bin/start-xvfb.sh
COPY app.py /app/app.py
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

RUN groupadd -g $USER_ID $USER
RUN useradd -rm -G sudo -u $USER_ID -g $USER_ID $USER

RUN mkdir -p /tmp/edge  /var/run/supervisor /var/log/supervisor
RUN chown "${USER_ID}:${USER_ID}" /var/run/supervisor /var/log/supervisor
RUN chown -R "${USER_ID}:${USER_ID}" /app /tmp/edge
RUN chmod 777 /tmp

USER $USER

ENV SCREEN_WIDTH=1360
ENV SCREEN_HEIGHT=1020
ENV SCREEN_DEPTH=24
ENV SCREEN_DPI=96
ENV SE_START_XVFB=true
ENV DISPLAY=:99.0
ENV DISPLAY_NUM=99

ENV PORT=45678
ENV BYPASS_SERVER=http://localhost:56789
ENV HEADLESS=false
ENV BROWSER_BINARY=/usr/bin/microsoft-edge
# ENV PASS_TIMEOUT=10
# ENV CHROME_PATH=/opt/google/chrome
ENV XDG_CONFIG_HOME=/tmp/edge
ENV XDG_CACHE_HOME=/tmp/edge

EXPOSE 7860

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf