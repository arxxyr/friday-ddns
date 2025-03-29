# Friday DDNS

> 声明：本项目是从[nickjer/namecheap-ddns](https://github.com/nickjer/namecheap-ddns) fork而来。

[![最新版本](https://img.shields.io/crates/v/friday-ddns.svg)](https://crates.io/crates/friday-ddns)
[![下载量](https://img.shields.io/github/downloads/arxxyr/friday-ddns/total.svg)](https://github.com/arxxyr/friday-ddns/releases)
[![许可证](https://img.shields.io/github/license/arxxyr/friday-ddns.svg)](https://github.com/arxxyr/friday-ddns)
[![持续集成状态](https://github.com/arxxyr/friday-ddns/workflows/Continuous%20integration/badge.svg)](https://github.com/arxxyr/friday-ddns/actions)

[English Version](README_EN.md)

这是一个命令行工具（CLI），用于更新Namecheap的A记录和动态DNS记录。

## 预编译二进制文件

你可以下载并运行[预编译的二进制文件]来立即开始使用。

## 安装

另一种方法是使用[cargo]进行安装：

```shell
cargo install friday-ddns
```

## 使用方法

查看帮助（`--help`）了解此工具的详细使用方法：

```shell
更新Namecheap的A记录和动态DNS记录

用法: friday-ddns [选项] --config <配置文件>

选项:
  -c, --config <配置文件>        YAML配置文件的路径 [环境变量: NAMECHEAP_DDNS_CONFIG=]
  -h, --help                   打印帮助信息
  -V, --version                打印版本信息
```

### YAML配置文件

程序现在使用YAML配置文件来支持多个域名和密码。以下是一个配置示例（`config.yaml`）：

```yaml
domains:
  # 第一个域名配置
  - domain: example.com
    token: abcdef123456  # Namecheap动态DNS密码
    subdomains:
      - "@"  # 根域名
      - "www"
      - "test"
    # ip: 198.51.100.1  # 可选，如果不提供则使用请求的IP地址

  # 第二个域名配置
  - domain: another-example.com
    token: xyz789abc
    subdomains:
      - "home"
      - "cloud"
    # ip: 203.0.113.10  # 可选
```

你需要在配置文件的`token`字段中指定Namecheap在高级DNS控制面板中提供给你的动态DNS密码。

> *提示：* 这不是你的Namecheap登录密码。

### 示例

更新配置文件中定义的所有域名和子域名：

```console
$ friday-ddns -c config.yaml
www.example.com IP地址已更新为: 123.123.123.123
test.example.com IP地址已更新为: 123.123.123.123
home.another-example.com IP地址已更新为: 123.123.123.123
cloud.another-example.com IP地址已更新为: 123.123.123.123
```

你也可以使用环境变量来指定配置文件：

```console
$ export NAMECHEAP_DDNS_CONFIG=/path/to/config.yaml
$ friday-ddns
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
   ExecStart=/path/to/friday-ddns -c /path/to/config.yaml
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
# 替换your-username为你的GitHub用户名
docker pull ghcr.io/your-username/friday-ddns:latest
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
# 替换your-username为你的GitHub用户名
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml \
  ghcr.io/your-username/friday-ddns:latest
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
git clone https://github.com/yourusername/friday-ddns.git
cd friday-ddns

# 构建镜像
docker build -t friday-ddns .

# 运行容器
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml friday-ddns
```

## 持续集成与自动构建

本项目使用GitHub Actions进行持续集成和自动构建：

1. **二进制发布**：当推送标签(如v1.0.0)时，会自动构建多平台二进制文件并创建GitHub发布
2. **Docker镜像构建**：
   - 推送到master分支时构建并推送最新的Docker镜像
   - 标签发布时构建并推送对应版本的Docker镜像
   - 支持多架构(amd64/arm64)镜像

[cargo]: https://doc.rust-lang.org/cargo/
[预编译的二进制文件]: https://github.com/arxxyr/friday-ddns/releases
