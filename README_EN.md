# Friday DDNS

> Disclaimer: This project is forked from [nickjer/namecheap-ddns](https://github.com/nickjer/namecheap-ddns).

[![Latest Version](https://img.shields.io/crates/v/friday-ddns.svg)](https://crates.io/crates/friday-ddns)
[![Downloads](https://img.shields.io/github/downloads/arxxyr/friday-ddns/total.svg)](https://github.com/arxxyr/friday-ddns/releases)
[![License](https://img.shields.io/github/license/arxxyr/friday-ddns.svg)](https://github.com/arxxyr/friday-ddns)
[![Continuous Integration Status](https://github.com/arxxyr/friday-ddns/workflows/Continuous%20integration/badge.svg)](https://github.com/arxxyr/friday-ddns/actions)

A command line interface (CLI) used to update the A + Dynamic DNS records for
Namecheap.

## Pre-compiled Binaries

You can download and run the [pre-compiled binaries] to get up and running
immediately.

## Installation

An alternative is to install using [cargo]:

```shell
cargo install friday-ddns
```

## Usage

Check the help (`--help`) for details on using this tool:

```shell
Updates the A + Dynamic DNS records for Namecheap

Usage: friday-ddns [OPTIONS] --config <CONFIG>

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
$ friday-ddns -c config.yaml
www.example.com IP address updated to: 123.123.123.123
test.example.com IP address updated to: 123.123.123.123
home.another-example.com IP address updated to: 123.123.123.123
cloud.another-example.com IP address updated to: 123.123.123.123
```

You can also use an environment variable to specify the configuration file:

```console
$ export NAMECHEAP_DDNS_CONFIG=/path/to/config.yaml
$ friday-ddns
```

## Linux - systemd

If you want to set this up as a service, you need to create a service file and a corresponding timer.

1. Create a service to update your subdomains:

   ```desktop
   # /etc/systemd/system/ddns-update.service

   [Unit]
   Description=Update Namecheap DDNS Records
   After=network-online.target

   [Service]
   Type=simple
   ExecStart=/path/to/friday-ddns -c /path/to/config.yaml
   User=<USER>

   [Install]
   WantedBy=default.target
   ```

   Make sure to fill in the correct binary path and configuration file path.

2. For security reasons, we should set strict permissions on the configuration file:

   ```shell
   sudo chmod 600 /path/to/config.yaml
   ```

3. Create a timer to run this service:

   ```desktop
   # /etc/systemd/system/ddns-update.timer

   [Unit]
   Description=Run DDNS update every 15 minutes
   Requires=ddns-update.service

   [Timer]
   Unit=ddns-update.service
   OnUnitInactiveSec=15m
   AccuracySec=1s

   [Install]
   WantedBy=timers.target
   ```

4. Now reload the daemon and start the service:

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start ddns-update.service ddns-update.timer
   ```

You can view the service logs using the following command:

```shell
sudo journalctl -u ddns-update.service
```

## Automatic Installation

To simplify the installation process, you can use the provided installation script for automatic setup:

```bash
# Ensure the script has execution permission
chmod +x install.sh

# Run the installation script with root privileges
sudo ./install.sh
```

The installation script will automatically:
1. Compile and install the program to /usr/local/bin
2. Create configuration directory and example configuration file
3. Install systemd service and timer
4. Enable and start the service

**Note:** After installation, make sure to edit the configuration file `/etc/friday-ddns/config.yaml` with your correct domain and key information.

## Docker Usage

### Pull Image from GitHub Container Registry

```bash
# Replace your-username with your GitHub username
docker pull ghcr.io/your-username/friday-ddns:latest
```

### Run with Docker

1. Create a `config.yaml` file:

```yaml
domains:
  - domain: example.com
    token: your_namecheap_ddns_password
    subdomains:
      - "@"
      - "www"
```

2. Run the Docker container:

```bash
# Replace your-username with your GitHub username
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml \
  ghcr.io/your-username/friday-ddns:latest
```

### Run with Docker Compose

1. Create a `docker-compose.yml` file and `config.yaml` configuration file

2. Start the service:

```bash
docker-compose up -d
```

### Build Docker Image Yourself

```bash
# Clone the repository
git clone https://github.com/yourusername/friday-ddns.git
cd friday-ddns

# Build the image
docker build -t friday-ddns .

# Run the container
docker run -v $(pwd)/config.yaml:/etc/friday-ddns/config.yaml friday-ddns
```

## Continuous Integration and Automated Builds

This project uses GitHub Actions for continuous integration and automated builds:

1. **Binary releases**: When pushing tags (e.g., v1.0.0), multi-platform binaries are automatically built and a GitHub release is created
2. **Docker image builds**:
   - Builds and pushes the latest Docker image when pushing to the master branch
   - Builds and pushes corresponding version Docker images when releasing tags
   - Supports multi-architecture (amd64/arm64) images

[cargo]: https://doc.rust-lang.org/cargo/
[pre-compiled binaries]: https://github.com/arxxyr/friday-ddns/releases 