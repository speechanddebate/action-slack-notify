FROM golang:1.21.0-alpine3.18 AS builder

LABEL "com.github.actions.icon"="bell"
LABEL "com.github.actions.color"="yellow"
LABEL "com.github.actions.name"="Slack Notify"
LABEL "com.github.actions.description"="This action will send notification to Slack"
LABEL "org.opencontainers.image.source"="https://github.com/speechanddebate/action-slack-notify"

WORKDIR ${GOPATH}/src/github.com/speechanddebate/action-slack-notify
COPY main.go ${GOPATH}/src/github.com/speechanddebate/action-slack-notify

ENV CGO_ENABLED 0
ENV GOOS linux

RUN go mod init
RUN go mod download
RUN go build -a -installsuffix cgo -ldflags '-w  -extldflags "-static"' -o /go/bin/slack-notify .

FROM alpine:3.18.3

COPY --from=builder /go/bin/slack-notify /usr/bin/slack-notify

ENV VAULT_VERSION 1.0.2

RUN apk update \
	&& apk upgrade \
	&& apk add \
	bash \
	jq \
	ca-certificates \
	python3 \
	rsync && \
	python3 -m ensurepip && \
	python3 -m pip install shyaml && \
	rm -rf /var/cache/apk/*

# fix the missing dependency - https://stackoverflow.com/a/35613430
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

COPY *.sh /

RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
