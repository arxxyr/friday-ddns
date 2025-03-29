FROM rustlang/rust:nightly as builder

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    build-essential \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# 提供详细输出便于调试
RUN cargo build --release --verbose || (cat /app/target/release/build/*/*/output 2>/dev/null || true && false)

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