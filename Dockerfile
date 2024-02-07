FROM zklcdc/go-bingai-pass:latest

ENV GBP_USER ${GBP_USER:-gbp}
ENV GBP_USER_ID ${GBP_USER_ID:-1000}

WORKDIR /app

USER root

RUN apt-get update && apt-get install -y --no-install-recommends curl jq

RUN curl -L https://github.com/Harry-zklcdc/go-proxy-bingai/releases/latest/download/go-proxy-bingai-linux-amd64.tar.gz -o go-proxy-bingai-linux-amd64.tar.gz && \
    tar -zxvf go-proxy-bingai-linux-amd64.tar.gz && \
    chmod +x go-proxy-bingai

RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared && \
    chmod +x cloudflared

RUN bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
    bash -c "$(curl -L wgcf-cli.vercel.app)" && \
    wgcf-cli -r && \
    wgcf-cli -g xray

COPY config.json /app/config.json

RUN TEMPLATE=$(jq -Rs . wgcf.json.xray.json | sed 's/^"//' | sed 's/"$//') && \
    sed -i "s|{{TEMPLATE}}|${TEMPLATE}|g" config.json

RUN apt-get remove -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm go-proxy-bingai-linux-amd64.tar.gz

COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

USER $GBP_USER

ENV PORT=7860
ENV BYPASS_SERVER=http://localhost:8080

ENV PROXY_SERVER=http://localhost:10808

ENV HTTP_PROXY=http://localhost:10808
ENV HTTPS_PROXY=http://localhost:10808

EXPOSE 7860

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf