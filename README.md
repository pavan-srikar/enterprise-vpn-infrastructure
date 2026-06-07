![Platform](https://img.shields.io/badge/platform-AWS-orange)
![VPN](https://img.shields.io/badge/VPN-WireGuard-blue)
![OS](https://img.shields.io/badge/OS-Ubuntu-green)
![Status](https://img.shields.io/badge/status-Active-success)
# Enterprise VPN Infrastructure

Enterprise-style WireGuard VPN infrastructure deployed on AWS to provide secure remote access to internal services, protected network environments, and private infrastructure resources.

---

## Overview

This project simulates a production-inspired enterprise VPN environment where remote users securely connect to internal company resources through encrypted WireGuard tunnels hosted on AWS.

The infrastructure was designed with security, network isolation, and future extensibility in mind, including support for planned enterprise features such as split tunneling, internal DNS resolution, infrastructure automation, centralized monitoring, and security hardening.

---

![Infrastructure](./diagrams/VPN-Infrastructure.png)

## Features

### Implemented

* WireGuard VPN deployment on AWS EC2
* Secure encrypted remote access
* Multi-device connectivity
* Linux-based networking stack
* NAT configuration using iptables
* IP forwarding
* Peer-based access management
* QR-based mobile onboarding
* Ubuntu server deployment

### Planned Enterprise Features

* Split tunneling support
* Internal DNS resolution
* Terraform infrastructure provisioning
* Automated peer lifecycle management
* Monitoring dashboards with Grafana/Prometheus
* Bastion-style internal resource access
* Security hardening automation
* Infrastructure-as-Code deployment workflows

---

## Architecture

Remote users connect securely to the AWS-hosted VPN gateway through encrypted WireGuard tunnels.

Internal resources are intended to remain inaccessible from the public internet and only reachable through authenticated VPN peers.

### High-Level Flow

Remote Device
↓
WireGuard Tunnel
↓
AWS EC2 VPN Gateway
↓
Internal Network Resources

---

## Technologies Used

* WireGuard
* AWS EC2
* Ubuntu Linux
* iptables
* Linux networking
* Bash scripting

---

## Networking

The VPN uses a private internal subnet:

Server → 10.0.0.1
Clients → 10.0.0.x

Traffic forwarding is enabled through Linux IP forwarding and NAT masquerading.

---

## Security Considerations

* Key-based authentication
* Encrypted WireGuard tunnels
* Controlled peer access
* Internal-only network design
* Firewall-based traffic routing
* AWS security group restrictions
* Planned SSH hardening and access isolation

---

## Example Use Cases

* Secure employee remote access
* Internal dashboard access
* Private infrastructure connectivity
* Bastion-style administration access
* Secure development environment access

---

## Future Improvements

* Internal DNS routing
* Split-tunnel optimization
* Automated provisioning using Terraform
* Peer onboarding automation
* Monitoring and traffic analytics
* Multi-region VPN deployment
* High availability failover nodes

---

## Disclaimer

This project is intended for educational, infrastructure engineering, and security research purposes.
