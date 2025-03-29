FROM ekidd/rust-musl-builder:nightly as builder

# 创建一个非root用户，因为rust-musl-builder默认使用rust用户
USER root
RUN apt-get update && \
    apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*
USER rust

# 复制源代码
WORKDIR /home/rust/src
COPY --chown=rust:rust . .

# 构建项目
RUN cargo build --release

FROM alpine:3.18

# 安装必要的CA证书
RUN apk add --no-cache ca-certificates

WORKDIR /app
# 复制静态编译的二进制文件
COPY --from=builder /home/rust/src/target/x86_64-unknown-linux-musl/release/friday-ddns /usr/local/bin/friday-ddns

# 创建配置目录
RUN mkdir -p /etc/friday-ddns

# 设置入口点
ENTRYPOINT ["friday-ddns", "-c", "/etc/friday-ddns/config.yaml"]

# 提供一个默认命令，但用户可以覆盖
CMD ["--help"] 