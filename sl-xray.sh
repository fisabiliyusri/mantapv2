#!/bin/bash
# mantapv2 SLXRAY
# =====================================================

# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

MYIP=$(wget -qO- ipinfo.io/ip);
clear
domain=$(cat /etc/xray/domain)
apt install iptables iptables-persistent -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
timedatectl set-ntp true
systemctl enable chronyd && systemctl restart chronyd
systemctl enable chrony && systemctl restart chrony
timedatectl set-timezone Asia/Jakarta
chronyc sourcestats -v
chronyc tracking -v
date

# / / Make Main Directory
mkdir -p /usr/bin/xray
mkdir -p /etc/xray
mkdir -p /etc/xray/conf
mkdir -p /etc/xray/v2ray/conf
mkdir -p /etc/xray/xray
mkdir -p /etc/xray/v2ray
mkdir -p /etc/xray/tls
mkdir -p /etc/xray/config-url
mkdir -p /etc/xray/config-user
mkdir -p /var/log/xray/
mkdir -p /var/log/v2ray/

# install
apt-get --reinstall --fix-missing install -y linux-headers-cloud-amd64 bzip2 gzip coreutils wget jq screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl git lsof
cat> /root/.profile << END
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n || true
clear
menu
END
chmod 644 /root/.profile
#
# install NGINX webserver
sudo apt install gnupg2 ca-certificates lsb-release -y 
echo "deb http://nginx.org/packages/mainline/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list 
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx 
curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key 
# gpg --dry-run --quiet --import --import-options import-show /tmp/nginx_signing.key
sudo mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
sudo apt update 
apt -y install nginx 
systemctl daemon-reload
systemctl enable nginx
#
sudo pkill -f nginx & wait $!
systemctl stop nginx
sudo apt install gnupg2 ca-certificates lsb-release -y
apt -y install nginx 
systemctl daemon-reload
systemctl enable nginx
touch /etc/nginx/conf.d/alone.conf
cat <<EOF >>/etc/nginx/conf.d/alone.conf
server {
	listen 81;
	listen [::]:81;
	server_name ${domain};
	# shellcheck disable=SC2154
	return 301 https://${domain};
}
server {
		listen 127.0.0.1:31300;
		server_name _;
		return 403;
}
server {
	listen 127.0.0.1:31302 http2;
	server_name ${domain};
	root /usr/share/nginx/html;
	location /s/ {
    		add_header Content-Type text/plain;
    		alias /etc/xray/config-url/;
    }

    location /xraygrpc {
		client_max_body_size 0;
#		keepalive_time 1071906480m;
		keepalive_requests 4294967296;
		client_body_timeout 1071906480m;
 		send_timeout 1071906480m;
 		lingering_close always;
 		grpc_read_timeout 1071906480m;
 		grpc_send_timeout 1071906480m;
		grpc_pass grpc://127.0.0.1:31301;
	}

	location /xraytrojangrpc {
		client_max_body_size 0;
		# keepalive_time 1071906480m;
		keepalive_requests 4294967296;
		client_body_timeout 1071906480m;
 		send_timeout 1071906480m;
 		lingering_close always;
 		grpc_read_timeout 1071906480m;
 		grpc_send_timeout 1071906480m;
		grpc_pass grpc://127.0.0.1:31304;
	}
}
server {
	listen 127.0.0.1:31300;
	server_name ${domain};
	root /usr/share/nginx/html;
	location /s/ {
		add_header Content-Type text/plain;
		alias /etc/xray/config-url/;
	}
	location / {
		add_header Strict-Transport-Security "max-age=15552000; preload" always;
	}
}
EOF
mkdir /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
rm /etc/nginx/conf.d/default.conf
systemctl daemon-reload
service nginx restart
cd
rm -rf /usr/share/nginx/html
wget -q -P /usr/share/nginx https://raw.githubusercontent.com/racunzx/hijk.art/main/html.zip 
unzip -o /usr/share/nginx/html.zip -d /usr/share/nginx/html 
rm -f /usr/share/nginx/html.zip*
chown -R www-data:www-data /usr/share/nginx/html

# / / Ambil Xray Core Version Terbaru
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"

# / / Installation Xray Core
xraycore_link="https://github.com/XTLS/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"

# / / Make Main Directory
mkdir -p /usr/bin/xray
mkdir -p /etc/xray
mkdir -p /etc/xray/conf

# / / Unzip Xray Linux 64
cd `mktemp -d`
curl -sL "$xraycore_link" -o xray.zip
unzip -q xray.zip && rm -rf xray.zip
mv xray /usr/local/bin/xray
chmod +x /usr/local/bin/xray

# Make Folder XRay
mkdir -p /var/log/xray/

sudo lsof -t -i tcp:80 -s tcp:listen | sudo xargs kill
cd /root/
wget https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh
bash acme.sh --install
rm acme.sh
cd .acme.sh
bash acme.sh --register-account -m slinfinity69@gmail.com
bash acme.sh --issue --standalone -d $domain --force
bash acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key

uuid1=$(cat /proc/sys/kernel/random/uuid)

# // Certificate File
path_crt="/etc/xray/xray.crt"
path_key="/etc/xray/xray.key"

# Buat Config Xray
#1
#LOG
cat > /etc/xray/conf/1log.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  }
}
END
#Port UTAMA 443
#2
#VLESS_TCP
cat > /etc/xray/conf/2vless.json << END
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "tag": "vlessTCP",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "add": "$domain",
            "flow": "xtls-rprx-direct",
            "email": "vlessTCP@XRAYbyRARE" 
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 31296,
            "xver": 1
          },
          {
            "alpn": "h2",
            "dest": 31302,
            "xver": 0
          },
          {
            "path": "/xrayws",
            "dest": 31297,
            "xver": 1
          },
          {
            "path": "/xrayvws",
            "dest": 31299,
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "minVersion": "1.2",
          "alpn": [
            "http/1.1",
            "h2"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key",
              "ocspStapling": 3600,
              "usage": "encipherment"
            }
          ]
        }
      }
    }
  ]
}
END
#3
#VLESS_H2
cat > /etc/xray/conf/3vless_h2.json << END
{
  "inbounds": [
    {
      "port": 100,
      "protocol": "vless",
      "tag": "vlessH2",
      "settings": {
        "clients": [
            {
                "id": "${uuid1}",
                "flow": "xtls-rprx-direct",
                "email": "vlessH2@XRAYbyRARE"                
            }
        ],
        "decryption": "none",
        "fallbacks": [
            {
                "dest": 65534
            }
        ],
        "fallbacks_h2": [
            {
                "dest": 65535 
            }
        ]
      },
      "streamSettings": {
        "network": "h2",
        "httpSettings": {
            "path": "/vlessh2"
        },
        "security": "tls",
        "tlsSettings": {
            "alpn": [
                "h2",
                "http/1.1"
            ],
            "certificates": [
                {
                    "certificateFile": "/etc/xray/xray.crt",
                    "keyFile": "/etc/xray/xray.key"
                }
            ]
        }
      },
      "domain": "$domain"
    }
  ]
}
END
#3
#VLESS_MKCPTLS
cat > /etc/xray/conf/3vless_mkcptls.json << END
{
  "inbounds": [
    {
      "port": 743,
      "protocol": "vless",
      "tag": "vlessMKCPwgTLS",
      "settings": {
        "clients": [
            {
              "id": "${uuid1}",
              "flow": "xtls-rprx-direct",
              "email": "vlessMKCPwgTLS@XRAYbyRARE"             
            }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": 31302,
            "xver": 0            
          }
        ]
      },
      "streamSettings": {
        "network": "kcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"              
            }
          ]
        },
        "kcpSettings": {
          "mtu": 1350,
          "tti": 50,
          "uplinkCapacity": 100,
          "downlinkCapacity": 100,
          "congestion": false,
          "readBufferSize": 2,
          "writeBufferSize": 2,
          "header": {
            "type": "wireguard"
          },
          "seed": "vlessmkcptls"
        },
        "wsSettings": {},
        "quicSettings": {}
      },
      "domain": "$domain",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
END
#3
#VLESS_MKCP
cat > /etc/xray/conf/3vless_mkcp.json << END
{
  "inbounds": [
    {
      "port": 7443,
      "protocol": "vless",
      "tag": "vlessMKCPwg",
      "settings": {
        "clients": [
            {
              "id": "${uuid1}",
              "flow": "xtls-rprx-direct",
              "email": "vlessMKCPwg@XRAYbyRARE"             
            }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": 31302,
            "xver": 0            
          }
        ]
      },
      "streamSettings": {
        "network": "kcp",
        "security": "none",
        "tlsSettings": {},
        "kcpSettings": {
          "mtu": 1350,
          "tti": 50,
          "uplinkCapacity": 100,
          "downlinkCapacity": 100,
          "congestion": false,
          "readBufferSize": 2,
          "writeBufferSize": 2,
          "header": {
            "type": "wireguard"
          },
          "seed": "vlessmkcp"
        },
        "wsSettings": {},
        "quicSettings": {}
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
END
#3
#VLESS_WS_NONE
cat > /etc/xray/conf/3vless_ws_none.json << END
{
  "inbounds": [
    {
      "port": 88,
      "protocol": "vless",
      "tag": "vlessWSNONE",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "email": "vlessWSNONE@XRAYbyRARE"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "tlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "httpSettings": {},
        "wsSettings": {
          "path": "/xrayws",
          "headers": {
            "Host": ""
          }
        },
        "quicSettings": {}
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
END
#3
#VLESS_WSTLS
cat > /etc/xray/conf/3vless_ws.json << END
{
  "inbounds": [
    {
      "port": 31297,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "tag": "vlessWSTLS",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "email": "vlessWSTLS@XRAYbyRARE"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/xrayws"
        }
      }
    }
  ]
}
END
#4
#trojan_GRPC_TCP
cat > /etc/xray/conf/4trojan_grpc.json << END
{
    "inbounds": [
        {
            "port": 31304,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "tag": "trojanGRPCTCP",
            "settings": {
                "clients": [
                    {
                        "password": "${uuid1}",
                        "email": "trojanGRPC@XRAYbyRARE"
                    }
                ],
                "fallbacks": [
                    {
                        "dest": "31300"
                    }
                ]
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": {
                    "serviceName": "xraytrojangrpctcp"
                }
            }
        }
    ]
}
END
#4
#trojan_TCP
cat > /etc/xray/conf/4trojan_tcp.json << END
{
  "inbounds": [
    {
      "port": 31296,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag": "trojanTCP",
      "settings": {
        "clients": [
          {
            "password": "${uuid1}",
            "email": "trojanTCP@XRAYbyRARE"
          }
        ],
        "fallbacks": [
          {
            "dest": "31300"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      }
    }
  ]
}
END
#4
#trojan_XTLS
cat > /etc/xray/conf/4trojan_xtls.json << END
{
    "inbounds": [
        {
            "port": 6443,
            "protocol": "trojan",
            "tag": "trojanXTLS",
            "settings": {
                "clients": [
                    {
                        "password": "${uuid1}",
                        "flow": "xtls-rprx-direct",
                        "email": "trojanXTLS@XRAYbyRARE"
                    }
                ],
                "fallbacks": [
                    {
                        "alpn": "h2",
                        "dest": 31302,
                        "xver": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "minVersion": "1.2",
                    "alpn": [
                        "http/1.1",
                        "h2"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/xray.crt",
                            "keyFile": "/etc/xray/xray.key"
                        }
                    ]
                },
                "domain": "$domain",
                "sniffing": {
                    "enabled": true,
                    "destOverride": [
                        "http",
                        "tls"
                    ]
                }
            }
        }
    ]
}
END
#5
#VMESS_WS_TLS
cat > /etc/xray/conf/5vmess_ws_tls.json << END
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 31299,
      "protocol": "vmess",
      "tag": "vmessWSTLS",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "add": "$domain",
            "email": "vmessWSTLS@XRAYbyRARE"            
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/xrayvws"
        }
      }
    }
  ]
}
END
#5
#VMESS_HTTPTLS
cat > /etc/xray/conf/5vmess_http_tls.json << END
{
  "inbounds": [
    {
      "port": 643,
      "protocol": "vmess",
      "tag": "vmessHTTPTLS",
      "settings": {
        "clients": [
            {
                "id": "${uuid1}",
                "email": "vmessHTTPTLS@XRAYbyRARE"                
            }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "video/mpeg",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"                  
                ],
                "Transfer-Encoding": [
                  "chunked"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }           
            }
          }
        },
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"              
            }
          ],
          "alpn": [
            "h2",
            "http/1.1"
          ]
        }
      },
      "domain": "$domain",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
END
#5
#VMESS_HTTP
cat > /etc/xray/conf/5vmess_http.json << END
{
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "tag": "vmessHTTP",
      "settings": {
        "clients": [
            {
                "id": "${uuid1}",
                "email": "vmessHTTP@XRAYbyRARE"                
            }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "video/mpeg",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"                  
                ],
                "Transfer-Encoding": [
                  "chunked"
                ],
                "Connection": [
                  "keep-alive"
                ],
                "Pragma": "no-cache"
              }           
            }
          }
        },
        "security": "none"
      }
    }
  ]
}
END
#5
#VMESS_TCPTLS
cat > /etc/xray/conf/5vmess_tcp_tls.json << END
{
  "inbounds": [
    {
      "port": 535,
      "protocol": "vmess",
      "tag": "vmessTCPTLS",
      "settings": {
        "clients": [
            {
                "id": "${uuid1}",
                "email": "vmessTCPTLS@XRAYbyRARE"                
            }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "alpn": [
                "h2",
                "http/1.1"
            ],
            "certificates": [
                {
                    "certificateFile": "/etc/xray/xray.crt",
                    "keyFile": "/etc/xray/xray.key"
                }
            ]
        },
        "wsSettings": {
            "path": "/xrayvws",
            "headers": {
                "Host": ""
            }
        }
      },
      "domain": "$domain",
      "sniffing": {
        "enabled": true,
        "destOverride": [
            "http",
            "tls"
        ]
      }
    }
  ]
}
END
#5
#VMess_WS_NONE
cat > /etc/xray/conf/5vmess_ws_none.json << END
{
  "inbounds": [
    {
      "port": 888,
      "protocol": "vmess",
      "tag": "vmessWSNONE",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "add": "$domain",
            "email": "vmessWSNONE@XRAYbyRARE" 
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "tlsSettings": {},
        "tcpSettings": {},
        "kcpSettings": {},
        "httpSettings": {},
        "wsSettings": {
          "path": "/xrayvws",
          "headers": {
            "Host": ""
          }
        },
        "quicSettings": {}
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
}
END
#5
#VLESS_GRPC
cat > /etc/xray/conf/5vless_grpc.json << END
{
  "inbounds": [
    {
      "port": 6643,
      "protocol": "vless",
      "tag": "vlessGRPC",
      "settings": {
        "clients": [
          {
            "id": "${uuid1}",
            "add": "$domain",
            "email": "vlessGRPC@XRAYbyRARE" 
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "gun",
        "security": "tls",
        "tlsSettings": {
          "serverName": "",
          "alpn": [
            "h2"
          ],
          "certificates": [
            {
              "certificateFile": "/etc/xray/xray.crt",
              "keyFile": "/etc/xray/xray.key"
            }
          ]
        },
        "grpcSettings": {
          "serviceName": "xraygrpc"
        }
      }
    }
  ]
}

END
#7
#shadowsocks
cat > /etc/xray/conf/7shadowsocks.json << END
{
  "inbounds": [
    {
      "port": 1111,
      "protocol": "shadowsocks",
      "tag": "shadowsocksAEAD",
      "settings": {
        "clients": [
            {
              "password": "${uuid1}",
              "method": "aes-128-gcm",
              "email": "aes-128-gcm@XRAYbyRARE"             
            },
            {
              "password": "${uuid1}",
              "method": "aes-256-gcm",
              "email": "aes-256-gcm@XRAYbyRARE"                 
            },
            {
              "password": "${uuid1}",
              "method": "chacha20-poly1305",
              "email": "chacha20-poly1305@XRAYbyRARE"                 
            }
        ],
        "network": "tcp,udp"
      }
    }
  ]
}
END
#10
#ipv4
cat > /etc/xray/conf/10ipv4.json << END
{
    "outbounds":[
        {
            "protocol":"freedom",
            "settings":{
                "domainStrategy":"UseIPv4"
            },
            "tag":"IPv4-out"
        },
        {
            "protocol":"freedom",
            "settings":{
                "domainStrategy":"UseIPv6"
            },
            "tag":"IPv6-out"
        },
        {
            "protocol":"blackhole",
            "settings": {},
            "tag": "blocked"
        },
        {
            "protocol": "freedom",
            "tag": "direct"        
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "ip": [
                    "0.0.0.0/8",
                    "10.0.0.0/8",
                    "100.64.0.0/10",
                    "169.254.0.0/16",
                    "172.16.0.0/12",
                    "192.0.0.0/24",
                    "192.0.2.0/24",
                    "192.168.0.0/16",
                    "198.18.0.0/15",
                    "198.51.100.0/24",
                    "203.0.113.0/24",
                    "::1/128",
                    "fc00::/7",
                    "fe80::/10"
                ],
                "outboundTag": "blocked"
            },
            {
                "inboundTag": [
                    "api"
                ],
                "outboundTag": "api",
                "type": "field"
            },
            {
                "type": "field",
                "outboundTag": "blocked",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    },
    "stats": {},
    "api": {
        "services": [
            "StatsService"
        ],
        "tag": "api"
    },
    "policy": {
        "levels": {
            "0": {
                "statsUserDownlink": true,
                "statsUserUplink": true
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true
        }
    }
}
END
#11
#dns
cat > /etc/xray/conf/11dns.json << END
{
    "dns": {
        "servers": [
          "localhost"
        ]
  }
}
END
#CONFIG_SELESAI
#

# / / Installation Xray Service
cat > /etc/systemd/system/xray.service << END
[Unit]
Description=Xray Service Mod By SL
Documentation=https://nekopoi.care
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -confdir /etc/xray/conf
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
END

# // Enable & Start Service
# xray
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 31301 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 31299 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 31296 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 31304 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 31297 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
# xray
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 31301 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 31299 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 31296 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 31304 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 31297 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
iptables-save >/etc/iptables.rules.v4
netfilter-persistent save
netfilter-persistent reload
systemctl daemon-reload

# Starting
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
systemctl restart xray.service
systemctl enable xray.service

systemctl daemon-reload
systemctl restart nginx
systemctl restart xray
# Accept port Xray
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8443 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2083 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2083 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
systemctl daemon-reload
systemctl stop xray.service
systemctl start xray.service
systemctl enable xray.service
systemctl restart xray.service
systemctl daemon-reload
systemctl restart nginx
systemctl restart xray

# Install Trojan Go
latest_version="$(curl -s "https://api.github.com/repos/p4gefau1t/trojan-go/releases" | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/v${latest_version}/trojan-go-linux-amd64.zip"
mkdir -p "/usr/bin/trojan-go"
mkdir -p "/etc/trojan-go"
cd `mktemp -d`
curl -sL "${trojango_link}" -o trojan-go.zip
unzip -q trojan-go.zip && rm -rf trojan-go.zip
mv trojan-go /usr/local/bin/trojan-go
chmod +x /usr/local/bin/trojan-go
mkdir /var/log/trojan-go/
touch /etc/trojan-go/akun.conf
touch /var/log/trojan-go/trojan-go.log

# Buat Config Trojan Go
cat > /etc/trojan-go/config.json << END
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 2087,
  "remote_addr": "127.0.0.1",
  "remote_port": 89,
  "log_level": 1,
  "log_file": "/var/log/trojan-go/trojan-go.log",
  "password": [
      "$uuid"
  ],
  "disable_http_check": true,
  "udp_timeout": 60,
  "ssl": {
    "verify": false,
    "verify_hostname": false,
    "cert": "/etc/xray/xray.crt",
    "key": "/etc/xray/xray.key",
    "key_password": "",
    "cipher": "",
    "curves": "",
    "prefer_server_cipher": false,
    "sni": "$domain",
    "alpn": [
      "http/1.1"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "",
    "fallback_addr": "127.0.0.1",
    "fallback_port": 0,
    "fingerprint": "firefox"
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "prefer_ipv4": true
  },
  "mux": {
    "enabled": false,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "websocket": {
    "enabled": true,
    "path": "/trojango",
    "host": "$domain"
  },
    "api": {
    "enabled": false,
    "api_addr": "",
    "api_port": 0,
    "ssl": {
      "enabled": false,
      "key": "",
      "cert": "",
      "verify_client": false,
      "client_cert": []
    }
  }
}
END

# Installing Trojan Go Service
cat > /etc/systemd/system/trojan-go.service << END
[Unit]
Description=Trojan-Go Service Mod By SL
Documentation=nekopoi.care
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
END

# Trojan Go Uuid
cat > /etc/trojan-go/uuid.txt << END
$uuid
END

# restart
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2086 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2087 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
systemctl daemon-reload
systemctl stop trojan-go
systemctl start trojan-go
systemctl enable trojan-go
systemctl restart trojan-go

cd
cp /root/domain /etc/xray
