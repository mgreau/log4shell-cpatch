# mgreau/log4shell-tools:1.0
FROM docker.io/ubuntu@sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322

RUN apt-get update && apt-get install curl -y

RUN curl -fsL https://github.com/google/log4jscanner/releases/download/v0.2.0/log4jscanner-v0.2.0-linux-amd64.tar.gz | tar xzf - -C /usr/local/bin  --strip-components 2 \
    && curl -fsL https://github.com/google/go-containerregistry/releases/download/v0.7.0/go-containerregistry_linux_x86_64.tar.gz | tar xzf - -C /usr/local/bin crane
