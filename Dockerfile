FROM rustlang/rust:nightly as builder

# 安装musl工具链和其他依赖
RUN apt-get update && \
    apt-get install -y \
    musl-tools \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 添加musl目标
RUN rustup target add x86_64-unknown-linux-musl

# 设置环境变量
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV OPENSSL_STATIC=true
ENV OPENSSL_DIR=/usr/include/openssl

WORKDIR /app
COPY . .

# 静态编译
RUN cargo build --release --target x86_64-unknown-linux-musl

FROM alpine:3.18

# 安装必要的CA证书
RUN apk add --no-cache ca-certificates

WORKDIR /app
# 复制静态编译的二进制文件
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/friday-ddns /usr/local/bin/friday-ddns

# 创建配置目录
RUN mkdir -p /etc/friday-ddns

# 设置入口点
ENTRYPOINT ["friday-ddns", "-c", "/etc/friday-ddns/config.yaml"]

# 提供一个默认命令，但用户可以覆盖
CMD ["--help"] 