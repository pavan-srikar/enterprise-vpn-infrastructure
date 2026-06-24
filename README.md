![Platform](https://img.shields.io/badge/platform-AWS-orange)
![VPN](https://img.shields.io/badge/VPN-WireGuard-blue)
![OS](https://img.shields.io/badge/OS-Ubuntu-green)
![Status](https://img.shields.io/badge/status-Active-success)

# Enterprise VPN Infrastructure

Enterprise-style WireGuard VPN deployed on AWS to provide secure remote access to private infrastructure and internal services.

## Overview

The goal is to simulate a real-world remote access solution where authenticated users can securely connect to internal resources through encrypted VPN tunnels instead of exposing services directly to the public internet.

The project includes automated VPN deployment, peer provisioning, QR-based onboarding, and configurable routing policies supporting split-tunnel and full-tunnel connectivity.

## Traffic 

```
Remote Device
↓
WireGuard VPN Tunnel
↓
AWS EC2 VPN Gateway
↓
Private Network Resources
```

![Infrastructure](./diagrams/VPN-Infrastructure.png)

## Features

### Implemented

* WireGuard VPN deployed and configured on AWS EC2
* Automated peer provisioning with QR-based mobile onboarding
* Clean peer removal with live interface update and config cleanup
* Split tunnel, enterprise, and full tunnel routing modes
* Automatic public IP detection with multi-endpoint fallback
* NAT and IP forwarding configured via iptables
* SSH access restricted to allowlisted IPs with Terraform-level validation
* S3 remote backend for Terraform state with versioning and encryption
* CI pipeline with ShellCheck, Terraform validate, and secret leak detection

### In Progress
* Internal DNS resolution
* Grafana and Prometheus monitoring
* GUI webpate to manage connections, metrics and dashboard 
* Bastion-style internal access workflows

---

## Networking

The VPN network uses the private subnet:

`VPN Server : 10.0.0.1`
`Clients    : 10.0.0.x`

Supported routing modes:

### Split Tunnel: `AllowedIPs = 10.0.0.0/24`
Only VPN network traffic is routed through WireGuard.

Example:
```
10.0.0.1  -> VPN Server
10.0.0.2  -> Mobile Device
10.0.0.3  -> Laptop
```

Internet traffic continues to use the client's normal connection.

### Enterprise Mode `AllowedIPs = 10.0.0.0/16`
Routes an entire private enterprise network through the VPN.

Example:
```
10.0.0.x  -> VPN Infrastructure
10.0.1.x  -> Applications
10.0.2.x  -> Databases
10.0.3.x  -> Monitoring
```

### Full Tunnel `AllowedIPs = 0.0.0.0/0`
Routes all internet traffic through the VPN gateway.

## Validation

The VPN was validated using a mobile WireGuard client.

## Infrastructure & Security

### Terraform State Management
Remote state is stored in an encrypted S3 bucket with versioning enabled.
State is never stored locally or committed to the repository.

### SSH Security
SSH access is restricted to explicitly allowlisted IPs via Terraform security group rules.
The configuration enforces this at the variable validation level — `0.0.0.0/0` is rejected at plan time.

### Secrets Management
- Private keys, `.pem` files, and `.tfvars` are excluded via `.gitignore`
- CI pipeline scans for accidentally committed secrets on every push

#### Testing confirmed:

- Successful VPN peer onboarding via QR code
- Secure client-to-server communication
- Split tunnel functionality
- Access to an internal HTTP service hosted on the VPN server
- WireGuard peer handshakes and traffic transfer verification

## Technologies Used
- AWS EC2, S3
- WireGuard
- Ubuntu Linux
- Bash, ShellCheck (bash linting)
- iptables
- Linux Networking
- Terraform (Infrastructure as Code)
- GitHub Actions (CI validation)

## Example Use Cases
- Secure employee remote access
- Internal dashboard access
- Private application access
- Infrastructure administration
- Development environment connectivity
- VPN gateway proof-of-concept deployments

## Future Improvements

* Internal DNS routing
* Split-tunnel optimization
* Monitoring and traffic analytics
* Multi-region VPN deployment
* High availability failover nodes

## Screenshots

![EC2](./screenshots/EC2.png)
![setup](./screenshots/setup.png)
![QR](./screenshots/QR.png)
![split tunnel](./screenshots/Split_Tunnel.png)

## Disclaimer

This project is intended for educational, infrastructure engineering, and security research purposes.
