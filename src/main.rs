extern crate clap;
extern crate minreq;
extern crate quick_xml;
extern crate serde_yaml;
extern crate url;

use anyhow::{Context, Result, anyhow};
use clap::Parser;
use quick_xml::de::from_str;
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;
use url::Url;

const API_URL: &str = "https://dynamicdns.park-your-domain.com/update";
const IP_DETECT_URL: &str = "https://dynamicdns.park-your-domain.com/getip";
// 备用IP检测服务
const BACKUP_IP_SERVICES: [&str; 3] = [
    "https://api.ipify.org",
    "https://ifconfig.me/ip",
    "https://icanhazip.com"
];

#[derive(Debug, Deserialize)]
struct ErrorList {
    #[serde(rename = "$value", default)]
    errors: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct Response {
    #[serde(rename = "IP")]
    ip: Option<String>,

    #[serde(rename = "ErrCount")]
    err_count: u8,

    #[serde(rename = "errors")]
    error_list: ErrorList,
}

impl Response {
    fn success(&self) -> bool {
        self.err_count == 0
    }

    fn error(&self) -> Option<String> {
        self.error_list.errors.first().cloned()
    }
}

#[derive(Deserialize, Debug)]
struct DomainConfig {
    domain: String,
    token: String,
    subdomains: Vec<String>,
    ip: Option<String>,
}

#[derive(Deserialize, Debug)]
struct Config {
    domains: Vec<DomainConfig>,
}

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Cli {
    /// Path to the YAML configuration file
    #[clap(short, long, env = "NAMECHEAP_DDNS_CONFIG")]
    config: PathBuf,
}

// 尝试从Namecheap官方服务获取IP
fn get_ip_from_namecheap() -> Result<String> {
    let response = minreq::get(IP_DETECT_URL)
        .with_timeout(10)
        .send()
        .with_context(|| format!("无法连接到Namecheap IP检测服务 {IP_DETECT_URL}"))?;
    
    let ip = response.as_str()?.trim().to_string();
    
    if ip.is_empty() {
        return Err(anyhow!("IP检测服务返回了空IP"));
    }
    
    Ok(ip)
}

// 从备用IP检测服务获取公网IP
fn get_ip_from_backup_services() -> Result<String> {
    for service in &BACKUP_IP_SERVICES {
        match minreq::get(*service).with_timeout(10).send() {
            Ok(response) => {
                if let Ok(ip_str) = response.as_str() {
                    let ip = ip_str.trim().to_string();
                    if !ip.is_empty() {
                        return Ok(ip);
                    }
                }
            }
            Err(_) => continue
        }
    }
    
    Err(anyhow!("所有备用IP检测服务均失败"))
}

// 获取当前公网IP，尝试多个服务
fn get_current_ip() -> Result<String> {
    // 首先尝试Namecheap官方服务
    match get_ip_from_namecheap() {
        Ok(ip) => {
            println!("从Namecheap获取到IP: {}", ip);
            Ok(ip)
        },
        Err(e) => {
            println!("Namecheap IP服务失败: {}，尝试备用服务...", e);
            // 尝试备用服务
            match get_ip_from_backup_services() {
                Ok(ip) => {
                    println!("从备用服务获取到IP: {}", ip);
                    Ok(ip)
                },
                Err(e) => Err(anyhow!("所有IP检测服务都失败: {}", e))
            }
        }
    }
}

fn update(domain: &str, subdomain: &str, token: &str, ip: Option<&str>) -> Result<()> {
    let mut url = Url::parse(API_URL)?;
    url.query_pairs_mut()
        .append_pair("domain", domain)
        .append_pair("host", subdomain)
        .append_pair("password", token);
    
    // 如果未提供IP，从IP检测服务获取当前IP
    let ip_value = match ip {
        Some(ip) => ip.to_string(),
        None => {
            println!("未指定IP地址，从IP检测服务获取...");
            get_current_ip()?
        }
    };
    
    // 现在总是添加IP参数
    url.query_pairs_mut().append_pair("ip", &ip_value);

    let response = minreq::get(url.as_str())
        .with_timeout(10)
        .send()
        .with_context(|| format!("Failed to connect to {API_URL}"))?;
    let body: Response = from_str(response.as_str()?)?;

    if body.success() {
        match body.ip {
            Some(ip) => {
                println!("{subdomain}.{domain} IP地址已更新为: {ip}");
                Ok(())
            }
            None => Err(anyhow!("响应中缺少IP地址")),
        }
    } else {
        match body.error() {
            Some(error) => Err(anyhow!("{error}")),
            None => Err(anyhow!("未知错误导致失败")),
        }
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // 读取YAML配置文件
    let config_content = fs::read_to_string(&cli.config)
        .with_context(|| format!("无法读取配置文件 {:?}", cli.config))?;

    let config: Config =
        serde_yaml::from_str(&config_content).with_context(|| "解析YAML配置文件失败")?;

    // 处理每个域名配置
    for domain_config in config.domains {
        let domain = domain_config.domain.clone();
        let token = domain_config.token.clone();
        let ip = domain_config.ip.as_deref();

        for subdomain in domain_config.subdomains {
            update(&domain, &subdomain, &token, ip)
                .with_context(|| format!("更新 {subdomain}.{domain} 失败"))?;
        }
    }

    Ok(())
}
