### Configure AWS credentials:

```bash
aws configure
```

### clone repo

```bash
git clone https://github.com/pavan-srikar/enterprise-vpn-infrastructure.git

cd enterprise-vpn-infrastructure

chmod +x scripts/*
```

### Configure `terraform.tfvars` inside terraform folder.

Enter your key name and IP by running `curl -4 ifconfig.me` 

```bash
key_name = "skibidi" 

ssh_allowed_cidr = [ # run: curl -4 ifconfig.me
  "157.49.21.47/32",
  "122.161.52.116/32",
  # "YOUR_SECOND_LAPTOP_IP/32",
  # "YOUR_PHONE_HOTSPOT_IP/32",
]
```

### Create S3 terraform state file
Create S3 Backend like the state file will be in S3 and will track changes like it remembers stuff you created etc, so it dosent create duplicates and shit

```bash
./scripts/setup-tf-backend.sh
```

it will give output like:
``` output
enterprise-vpn-tfstate-473157802330
```

#### copy that and paste it in `terraform/provider.tf`

uncomment this block after pasting this shi

```bash
backend "s3" {
  bucket  = "enterprise-vpn-tfstate-473157802330"
  key     = "vpn-infrastructure/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
}
```

### Initialize and Deploy Terraform

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply
```

Type:

```
yes
```

Terraform creates:

- VPC
- Subnet
- Route Table
- Internet Gateway
- Security Group
- Elastic IP
- EC2 Instance

Deployment takes around 2-5 minutes.

### Get EC2 IP

I set it up in a way it prints all details including IP, in case if you missed it just type.

```
terraform output
```

You should get something like:

```
vpn_instance_public_ip = 44.xxx.xxx.xxx
```

---

### SSH into the Server

Terraform outputs the public IP.

Connect:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<PUBLIC_IP>
```


```bash
ssh -i ~/Downloads/skibidi.pem ubuntu@3.236.166.199
```


### Install WireGuard and stuff using scripts

Inside the VM:

```bash
git clone https://github.com/pavan-srikar/enterprise-vpn-infrastructure.git

chmod +x scripts/*

sudo bash scripts/setup-wireguard.sh
```

When finished, verify:

```bash
sudo wg show
```

You should see interface `wg0`.

---

### Create First VPN User

```bash
sudo ./scripts/add-peer.sh phone 10.0.0.2 split
```

Generate QR:

```bash
sudo ./scripts/generate-qr.sh /etc/wireguard/peers/phone/client.conf
```

---

### Connect Phone

Install the official WireGuard app and scan the QR.

Then check:

```
sudo wg show
```

If you see:

```
latest handshake: few seconds ago
```

the VPN is alive and cooking.

### Connect laptop

i use endeavor so 
```bash
sudo pacman -S wireguard-tools
```

just copy the `.conf` file output u just generated to your laptop
```bash
sudo cat /etc/wireguard/peers/laptop/client.conf
```

### IMPORTANT: comment out the dns 1.1.1.1 line in the conf file before you copy

copy that .conf 
```bash
sudo cp client.conf /etc/wireguard/wg0.conf
```

enable vpn(wireguard)
```bash
sudo wg-quick up wg0
```

check status
```bash
sudo wg
```


### Run the monitoring script
```bash
sudo ./scripts/setup-monitoring.sh
```

### Open Grafana

Go to

```
http://10.0.0.1:3000
```

Login:

```bash
Username: admin
Password: admin
```

It'll ask you to change the password.

---

### Add Prometheus

On the left sidebar:

```
Connections    
↓
Data Sources    
↓
Add data source
```

Choose:

```
Prometheus
```

For URL enter:

```
http://localhost:9090
```

Not `10.0.0.1`, not the EC2 public IP. Grafana is running on the same server as Prometheus, so `localhost` is correct.

Leave everything else at the defaults.

##### Click:

```
Save & Test
```

You should see:

```
Data source is working
```

---

### Import a dashboard

On the left:

```
Dashboards    
↓
New    
↓
Import
```

Dashboard ID:

```
1860
```

Click:

```
Load
```

For datasource choose:

```
Prometheus
```

Click:

```
Import
```

You should now have graphs for:

- CPU Usage
- RAM Usage
- Disk Usage
- Network Traffic
- Filesystem
- Load Average
- Uptime
- Temperature (if available)

Basically everything Node Exporter exposes.

### Custom dashboard for WireGuard 

`wireguard-metrics.sh`

To get the metrics for dashboard we need a script that exports wireguard data every 1 minute.

```bash
cd scripts/
sudo cp wireguard-metrics.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wireguard-metrics.sh # main script
sudo /usr/local/bin/wireguard-metrics.sh
```


Verify:

```bash
crontab -l
```

You should see:

```bash
* * * * * /usr/local/bin/wireguard-metrics.sh
```

Then wait a minute and confirm it's updating:

```bash
stat /var/lib/node_exporter/textfile_collector/wireguard.prom
```

The **Modify** timestamp should refresh every minute.

Verify Node Exporter sees the metrics

```
curl localhost:9100/metrics | grep wireguard
```

You should see metrics like

```
wireguard_peers
wireguard_peer_connected
wireguard_received_bytes
wireguard_sent_bytes
```


### Import the custom dashboard json

Add Prometheus datasource or if already added click save and test.
You can also go to explore and test if you are getting prometheus data by running queries for `wireguard_peers`

Go to

```bash
Dashboards    
↓
New    
↓
Import (paste the json from enterprise-vpn-infrastructure/monitoring/dashboards)
```

select

```
Datasource → Prometheus
```

Click

```
Import
```



### Dashboard

Instead of manually making panels, create a dashboard with these PromQL queries:

|Panel|Query|
|---|---|
|Connected Peers|`sum(wireguard_peer_connected)`|
|Configured Peers|`wireguard_peers`|
|Total RX|`sum(wireguard_received_bytes)`|
|Total TX|`sum(wireguard_sent_bytes)`|
|RX Speed|`sum(rate(wireguard_received_bytes[5m]))`|
|TX Speed|`sum(rate(wireguard_sent_bytes[5m]))`|
|Peer Status|`wireguard_peer_connected`|
|Latest Handshake|`time() - wireguard_latest_handshake_seconds`|

That already looks surprisingly polished.


### Destroy Infrastructure

```bash
terraform destroy
```

Type

```
yes
```

This removes all AWS resources.


Also delete S3 Bucket


### small overview

```bash
Internet
     │
Terraform
     │
AWS EC2
     │
WireGuard VPN
     │
10.0.0.1
     │
 ┌───────────────┐
 │   Grafana     │ :3000
 └──────▲────────┘
        │
        │ queries
        │
 ┌──────┴────────┐
 │ Prometheus    │ :9090
 └──────▲────────┘
        │ scrapes
        │
 ┌──────┴────────┐
 │ Node Exporter │ :9100
 └───────────────┘
```