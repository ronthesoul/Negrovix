# 💻Negrovix

Negrovix is a Bash script designed to automate the creation of **Nginx configuration files**. It simplifies the setup of virtual hosts, SSL certificates, user authentication, and directory configurations for Nginx servers.

## 📝 Features
- Automatically installs required dependencies (Nginx, Apache2-utils, etc.).
- Creates Nginx virtual host configuration files.
- Supports SSL certificate configuration.
- Enables HTTP basic authentication.
- Configures user directories.
- Can configure CGI scripting.
- Automaticly adds /etc/hosts entry if wanted
- Performs syntax checks and restarts Nginx safely.


### 🚀 Usage
Run the script with the required options:
```bash
./negrovix.sh -d <domain> [-s <certfile>:<keyfile>] [-f <html file>] [-u <username>:<user dir>] [-a <auth path>:<username>:<password>]
```

### 🛠️ Options:
| Flag | Description |
|------|-------------|
| `-d <domain>` | Specifies the domain name (Required). |
| `-s <certfile>:<keyfile>` | Enables SSL and sets the certificate and key file. |
| `-f <html file>` | Defines the main HTML file. |
| `-u <username>:<user dir>` | Sets up user directory configuration. |
| `-a <auth path>:<username>:<password>` | Enables HTTP basic authentication. |
| `-c <cgi file name>` | Enables cgi-bin scripting, using fcgi |
| `-h` | Displays help information. |

### 📥 Installation
The first run would most likely install all the required packages. 
```bash
curl -sSLo negrovix.sh https://raw.githubusercontent.com/ronthesoul/negrovix/refs/heads/main/negrovix.sh && chmod +x negrovix.sh
```

### Clone the Repository:
```bash
 git clone https://github.com/ronthesoul/negrovix.git
 cd negrovix
 chmod +x negrovix.sh
```

### Example Usage
Create an Nginx configuration for `example.com` and also create a userdir:
```bash
sudo ./negrovix.sh -d example.com -u username:public_html
```

Enable SSL with a certificate and key:
```bash
sudo ./negrovix.sh -d example.com -s /etc/ssl/cert.pem:/etc/ssl/key.pem
```

Enable basic authentication:
```bash
sudo ./negrovix.sh -d example.com -a /admin:user:password
```

## 🔧 Prerequisites
-  **Operating System**: Debian-based Linux distributions (Ubuntu, Debian, etc.)
-  **Shell**: Bash (must be installed)

## Contributors 
The project was done by myself [Contributors](https://github.com/ronthesoul/Negrovix/blob/main/CONTRIBUTORS.md).

## Task
The task we were given is to make a tool to automaticly genereate nginx config file - [Task](https://github.com/ronthesoul/Negrovix/blob/main/TASKS.md).

## 👤 Author
Created by [ronthesoul](https://github.com/ronthesoul).

