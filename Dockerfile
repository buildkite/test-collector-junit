FROM alpine:latest

RUN apk update && \
    apk add bash jq curl

WORKDIR /app

ADD test-collector /app

ENTRYPOINT [ "/app/buildkite-collect-junit" ]
