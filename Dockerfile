FROM rust:alpine as builder

# 安装构建依赖
RUN apk add --no-cache musl-dev pkgconfig openssl-dev build-base

# 安装并配置nightly工具链
RUN rustup default nightly && \
    rustup target add x86_64-unknown-linux-musl

# 设置使用musl-libc
ENV RUSTFLAGS='-C link-arg=-s'

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