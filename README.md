# Namecheap DDNS

[![Latest Version](https://img.shields.io/crates/v/namecheap-ddns.svg)](https://crates.io/crates/namecheap-ddns)
[![Downloads](https://img.shields.io/github/downloads/nickjer/namecheap-ddns/total.svg)](https://github.com/nickjer/namecheap-ddns/releases)
[![License](https://img.shields.io/github/license/nickjer/namecheap-ddns.svg)](https://github.com/nickjer/namecheap-ddns)
[![Continuous Integration Status](https://github.com/nickjer/namecheap-ddns/workflows/Continuous%20integration/badge.svg)](https://github.com/nickjer/namecheap-ddns/actions)

A command line interface (CLI) used to update the A + Dynamic DNS records for
Namecheap.

## Pre-compiled Binaries

You can download and run the [pre-compiled binaries] to get up and running
immediately.

## Installation

An alternative is to install using [cargo]:

```shell
cargo install namecheap-ddns
```

## Usage

Check the help (`--help`) for details on using this tool:

```shell
Updates the A + Dynamic DNS records for Namecheap

Usage: namecheap-ddns [OPTIONS] --config <CONFIG>

Options:
  -c, --config <CONFIG>        Path to the YAML configuration file [env: NAMECHEAP_DDNS_CONFIG=]
  -h, --help                   Print help
  -V, --version                Print version
```

### YAML Configuration File

The program now uses a YAML configuration file to support multiple domains and passwords. Here's an example configuration (`config.yaml`):

```yaml
domains:
  # First domain configuration
  - domain: example.com
    token: abcdef123456  # Namecheap Dynamic DNS Password
    subdomains:
      - "@"  # Root domain
      - "www"
      - "test"
    # ip: 198.51.100.1  # Optional, if not provided uses the IP of the request

  # Second domain configuration
  - domain: another-example.com
    token: xyz789abc
    subdomains:
      - "home"
      - "cloud"
    # ip: 203.0.113.10  # Optional
```

You will need to specify Namecheap's Dynamic DNS Password provided to you in
their Advanced DNS control panel as the `token` in your configuration file.

> *Tip:* This is not your Namecheap login password.

### Examples

Update all domains and subdomains defined in your configuration file:

```console
$ namecheap-ddns -c config.yaml
www.example.com IP地址已更新为: 123.123.123.123
test.example.com IP地址已更新为: 123.123.123.123
home.another-example.com IP地址已更新为: 123.123.123.123
cloud.another-example.com IP地址已更新为: 123.123.123.123
```

You can also use an environment variable to specify the configuration file:

```console
$ export NAMECHEAP_DDNS_CONFIG=/path/to/config.yaml
$ namecheap-ddns
```

## Linux - systemd

如果你想将其设置为服务，你需要创建一个服务文件和相应的定时器。

1. 创建更新子域名的服务：

   ```desktop
   # /etc/systemd/system/ddns-update.service

   [Unit]
   Description=更新Namecheap的DDNS记录
   After=network-online.target

   [Service]
   Type=simple
   ExecStart=/path/to/namecheap-ddns -c /path/to/config.yaml
   User=<USER>

   [Install]
   WantedBy=default.target
   ```

   确保填写正确的二进制文件路径和配置文件路径。

2. 为了安全起见，我们应该为配置文件设置严格的权限：

   ```shell
   sudo chmod 600 /path/to/config.yaml
   ```

3. 创建运行此服务的定时器：

   ```desktop
   # /etc/systemd/system/ddns-update.timer

   [Unit]
   Description=每15分钟运行DDNS更新
   Requires=ddns-update.service

   [Timer]
   Unit=ddns-update.service
   OnUnitInactiveSec=15m
   AccuracySec=1s

   [Install]
   WantedBy=timers.target
   ```

4. 现在我们重新加载守护进程并启动服务：

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start ddns-update.service ddns-update.timer
   ```

你可以使用以下命令查看服务日志：

```shell
sudo journalctl -u ddns-update.service
```

## 自动安装

为了简化安装过程，可以使用提供的安装脚本进行自动安装：

```bash
# 确保脚本具有执行权限
chmod +x install.sh

# 以root权限运行安装脚本
sudo ./install.sh
```

安装脚本将自动完成以下操作：
1. 编译并安装程序到/usr/local/bin
2. 创建配置目录和示例配置文件
3. 安装systemd服务和定时器
4. 启用并启动服务

**注意：** 安装后请确保编辑配置文件`/etc/friday-ddns/config.yaml`，填入正确的域名和密钥信息。

## Docker 使用方法

### 从GitHub容器仓库拉取镜像

```bash
docker pull ghcr.io/yourusername/namecheap-ddns:latest
```

### 使用Docker运行

1. 创建配置文件`config.yaml`：

```yaml
domains:
  - domain: example.com
    token: your_namecheap_ddns_password
    subdomains:
      - "@"
      - "www"
```

2. 运行Docker容器：

```bash
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml \
  ghcr.io/yourusername/namecheap-ddns:latest
```

### 使用Docker Compose运行

1. 创建`docker-compose.yml`文件和`config.yaml`配置文件

2. 启动服务：

```bash
docker-compose up -d
```

### 自行构建Docker镜像

```bash
# 克隆仓库
git clone https://github.com/yourusername/namecheap-ddns.git
cd namecheap-ddns

# 构建镜像
docker build -t namecheap-ddns .

# 运行容器
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml namecheap-ddns
```

## 持续集成与自动构建

本项目使用GitHub Actions进行持续集成和自动构建：

1. **二进制发布**：当推送标签(如v1.0.0)时，会自动构建多平台二进制文件并创建GitHub发布
2. **Docker镜像构建**：
   - 推送到main分支时构建并推送最新的Docker镜像
   - 标签发布时构建并推送对应版本的Docker镜像
   - 支持多架构(amd64/arm64)镜像

[cargo]: https://doc.rust-lang.org/cargo/
[pre-compiled binaries]: https://github.com/nickjer/namecheap-ddns/releases
