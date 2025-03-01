# Negrovix

Negrovix is a Bash script designed to automate the creation of **Nginx configuration files**. It simplifies the setup of virtual hosts, SSL certificates, user authentication, and directory configurations for Nginx servers.

## Features
- Automatically installs required dependencies (Nginx, Apache2-utils, etc.).
- Creates Nginx virtual host configuration files.
- Supports SSL certificate configuration.
- Enables HTTP basic authentication.
- Configures user directories.
- Performs syntax checks and restarts Nginx safely.

## Installation
To use **Negrovix**, you must have **Bash** and **Nginx** installed. If not, the script will install missing dependencies.

### Clone the Repository:
```bash
 git clone https://github.com/ronthesoul/negrovix.git
 cd negrovix
 chmod +x negrovix.sh
```

## Usage
Run the script with the required options:
```bash
./negrovix.sh -d <domain> [-s <certfile>:<keyfile>] [-f <html file>] [-u <user root>:<user dir>] [-a <auth path>:<username>:<password>]
```

### Options:
| Flag | Description |
|------|-------------|
| `-d <domain>` | Specifies the domain name (Required). |
| `-s <certfile>:<keyfile>` | Enables SSL and sets the certificate and key file. |
| `-f <html file>` | Defines the main HTML file. |
| `-u <user root>:<user dir>` | Sets up user directory configuration. |
| `-a <auth path>:<username>:<password>` | Enables HTTP basic authentication. |
| `-h` | Displays help information. |

### Example Usage
Create an Nginx configuration for `example.com`:
```bash
./negrovix.sh -d example.com -f index.html
```

Enable SSL with a certificate and key:
```bash
./negrovix.sh -d example.com -s /etc/ssl/cert.pem:/etc/ssl/key.pem
```

Enable basic authentication:
```bash
./negrovix.sh -d example.com -a /secure:path:user:password
```

## Debugging
To debug the script execution, use:
```bash
bash -x ./negrovix.sh -d example.com
```

## Contributing
Contributions are welcome! Feel free to open an issue or submit a pull request.

## License
This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

