FROM arm64v8/golang:1.11-alpine as builder

ENV DISTRIBUTION_DIR /go/src/github.com/docker/distribution
ENV DOCKER_BUILDTAGS include_oss include_gcs

ARG GOOS=linux
ARG GOARCH=arm64

RUN set -ex \
    && apk add --no-cache make git file

ARG VERSION=master
RUN git clone -b $VERSION https://github.com/docker/distribution.git $DISTRIBUTION_DIR

WORKDIR $DISTRIBUTION_DIR
COPY . $DISTRIBUTION_DIR
RUN CGO_ENABLED=0 make PREFIX=/go clean binaries && file ./bin/registry | grep "statically linked"

# Build a minimal distribution container
FROM arm64v8/alpine

RUN set -ex \
    && apk add --no-cache ca-certificates apache2-utils

COPY --from=builder /go/src/github.com/docker/distribution/bin/registry /bin/registry
COPY --from=builder /go/src/github.com/docker/distribution/cmd/registry/config-dev.yml /etc/docker/registry/config.yml

VOLUME ["/var/lib/registry"]
EXPOSE 5000
ENTRYPOINT ["/bin/registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]

