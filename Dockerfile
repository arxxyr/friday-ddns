FROM clux/muslrust:nightly AS builder

WORKDIR /usr/src
COPY . .

RUN cargo build --release

FROM alpine:3.18

RUN apk add --no-cache ca-certificates

COPY --from=builder /usr/src/target/x86_64-unknown-linux-musl/release/friday-ddns /usr/local/bin/friday-ddns

RUN mkdir -p /etc/friday-ddns

ENTRYPOINT ["friday-ddns", "-c", "/etc/friday-ddns/config.yaml"]
CMD ["--help"] 