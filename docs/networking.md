# Networking Overview

The VPN infrastructure uses WireGuard to establish encrypted peer-to-peer tunnels between remote devices and the AWS-hosted VPN gateway.

---

## Internal VPN Subnet

The VPN network uses the private subnet:

10.0.0.0/24

Example peer assignments:

* VPN Gateway → 10.0.0.1
* Remote Laptop → 10.0.0.2
* Mobile Device → 10.0.0.3

---

## IP Forwarding

Linux IP forwarding is enabled to allow the EC2 instance to route traffic between VPN peers and external networks.

Configuration:

```bash
net.ipv4.ip_forward=1
```

---

## NAT Configuration

iptables NAT masquerading is used to allow VPN client traffic to exit through the EC2 network interface.

Example configuration:

```bash
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

---

## Peer Management

Each remote device receives:

* unique private/public key pair
* dedicated VPN IP address
* peer-specific configuration

Example:

```ini
[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
```

---

## Planned Networking Enhancements

### Split Tunneling

Future implementation will route only internal infrastructure traffic through the VPN while preserving direct internet access for normal browsing.

### Internal DNS Resolution

Internal services are planned to use private DNS entries such as:

* grafana.internal
* git.internal
* jenkins.internal

### Bastion Architecture

The VPN gateway is intended to act as a secure entry point for accessing internal infrastructure resources hosted in private subnets.

---

## Routing Design

Remote Device
↓
WireGuard Tunnel
↓
AWS VPN Gateway
↓
Private Internal Resources
