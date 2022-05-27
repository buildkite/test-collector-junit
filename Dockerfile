FROM alpine:latest

RUN apk update && \
    apk add bash jq curl

WORKDIR /app

ADD buildkite-collector-junit /app

ENTRYPOINT [ "/app/buildkite-collect-junit" ]
