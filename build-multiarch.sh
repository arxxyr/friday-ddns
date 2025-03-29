#!/bin/bash
set -e

# 确保有执行权限：chmod +x build-multiarch.sh

# 构建AMD64镜像
cat > Dockerfile.amd64 << 'EOF'
FROM messense/rust-musl-cross:x86_64-musl AS builder

WORKDIR /usr/src
COPY . .

# 构建项目
RUN cargo build --release

FROM alpine:3.18

# 安装必要的CA证书
RUN apk add --no-cache ca-certificates

WORKDIR /app
# 复制静态编译的二进制文件
COPY --from=builder /usr/src/target/x86_64-unknown-linux-musl/release/friday-ddns /usr/local/bin/friday-ddns

# 创建配置目录
RUN mkdir -p /etc/friday-ddns

# 设置入口点
ENTRYPOINT ["friday-ddns", "-c", "/etc/friday-ddns/config.yaml"]

# 提供一个默认命令，但用户可以覆盖
CMD ["--help"]
EOF

# 构建ARM64镜像
cat > Dockerfile.arm64 << 'EOF'
FROM messense/rust-musl-cross:aarch64-musl AS builder

WORKDIR /usr/src
COPY . .

# 构建项目
RUN cargo build --release

FROM arm64v8/alpine:3.18

# 安装必要的CA证书
RUN apk add --no-cache ca-certificates

WORKDIR /app
# 复制静态编译的二进制文件
COPY --from=builder /usr/src/target/aarch64-unknown-linux-musl/release/friday-ddns /usr/local/bin/friday-ddns

# 创建配置目录
RUN mkdir -p /etc/friday-ddns

# 设置入口点
ENTRYPOINT ["friday-ddns", "-c", "/etc/friday-ddns/config.yaml"]

# 提供一个默认命令，但用户可以覆盖
CMD ["--help"]
EOF

# 构建镜像
echo "构建AMD64镜像..."
docker build -t friday-ddns:amd64 -f Dockerfile.amd64 .

echo "构建ARM64镜像..."
docker build -t friday-ddns:arm64 -f Dockerfile.arm64 .

# 创建多架构清单（需要Docker CLI实验特性支持）
echo "创建多架构镜像..."
docker manifest create friday-ddns:latest \
  friday-ddns:amd64 \
  friday-ddns:arm64

# 推送多架构镜像（如果需要）
# echo "推送多架构镜像..."
# docker manifest push friday-ddns:latest

echo "完成！"
echo "现在您可以使用 friday-ddns:latest 镜像，它会自动选择适合您架构的版本。" 