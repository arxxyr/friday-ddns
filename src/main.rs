extern crate clap;
extern crate minreq;
extern crate quick_xml;
extern crate url;
extern crate serde_yaml;

use anyhow::{Context, Result, anyhow};
use clap::Parser;
use quick_xml::de::from_str;
use serde::Deserialize;
use url::Url;
use std::fs;
use std::path::PathBuf;

const API_URL: &str = "https://dynamicdns.park-your-domain.com/update";

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

fn update(domain: &str, subdomain: &str, token: &str, ip: Option<&str>) -> Result<()> {
    let mut url = Url::parse(API_URL)?;
    url.query_pairs_mut()
        .append_pair("domain", domain)
        .append_pair("host", subdomain)
        .append_pair("password", token);
    if let Some(ip) = ip {
        url.query_pairs_mut().append_pair("ip", ip);
    }

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
    
    let config: Config = serde_yaml::from_str(&config_content)
        .with_context(|| "解析YAML配置文件失败")?;

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
