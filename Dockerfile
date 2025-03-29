FROM rust:1.76-slim as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/namecheap-ddns /usr/local/bin/namecheap-ddns

# 创建配置目录
RUN mkdir -p /etc/friday-ddns

# 设置入口点
ENTRYPOINT ["namecheap-ddns", "-c", "/etc/friday-ddns/config.yaml"]

# 提供一个默认命令，但用户可以覆盖
CMD ["--help"] 