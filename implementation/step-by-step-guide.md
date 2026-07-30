# Step-by-Step Implementation Guide

> Follow this exactly. After each step, take a screenshot for your project documentation.

---

## Prerequisites

- AWS Account (Free Tier is fine)
- Logged into AWS Console as IAM user (NOT root — security best practice)
- Region: ap-south-1 (Mumbai) recommended for Indian students

---

## Phase 1: Create the VPC

### Step 1 — Navigate to VPC Dashboard
1. Go to AWS Console → Search "VPC" → Click VPC
2. Click **"Create VPC"**
3. Select **"VPC and more"** (this auto-creates subnets, route tables, IGW)

### Step 2 — Configure VPC Settings
```
Name tag:           secure-vpc-project
IPv4 CIDR:          10.0.0.0/16
IPv6:               No IPv6 CIDR block
Tenancy:            Default

Number of AZs:      2
Number of public subnets:   2
Number of private subnets:  2

Public subnet CIDRs:
  AZ-1a: 10.0.1.0/24
  AZ-1b: 10.0.2.0/24

Private subnet CIDRs:
  AZ-1a: 10.0.3.0/24
  AZ-1b: 10.0.4.0/24

NAT gateways:       1 per AZ  (select "In 1 AZ" to save cost for this project)
VPC endpoints:      None
DNS hostnames:      Enable ✅
DNS resolution:     Enable ✅
```

4. Click **"Create VPC"**
5. Wait 2-3 minutes. AWS creates: VPC + 4 subnets + IGW + NAT GW + 2 route tables

📸 **Screenshot:** The VPC resource map showing all components created

---

## Phase 2: Verify Route Tables

### Step 3 — Check Public Route Table
1. VPC Dashboard → Route Tables
2. Find the route table associated with public subnets
3. Verify it has these routes:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       igw-xxxxxxxx   ← This is what makes it "public"
```

### Step 4 — Check Private Route Table
1. Find the route table associated with private subnets
2. Verify it has:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       nat-xxxxxxxx   ← NAT Gateway, NOT IGW
```

⚠️ **Key difference:** Public subnets route to IGW (internet), private subnets route to NAT GW.

📸 **Screenshot:** Both route tables side by side

---

## Phase 3: Create Security Groups

### Step 5 — Create ALB Security Group (Public-facing)
1. VPC Dashboard → Security Groups → Create Security Group
```
Name:        alb-security-group
Description: Security group for Application Load Balancer
VPC:         secure-vpc-project (select your VPC)
```

**Inbound Rules:**
```
Type    Protocol  Port  Source
HTTP    TCP       80    0.0.0.0/0   (allow all internet HTTP)
HTTPS   TCP       443   0.0.0.0/0   (allow all internet HTTPS)
```

**Outbound Rules:**
```
Type          Protocol  Port  Destination
All traffic   All       All   0.0.0.0/0
```

### Step 6 — Create EC2 Security Group (Private servers)
```
Name:        ec2-private-security-group
Description: Security group for private EC2 instances - allows traffic from ALB only
VPC:         secure-vpc-project
```

**Inbound Rules:**
```
Type    Protocol  Port  Source
HTTP    TCP       80    [Select: alb-security-group]  ← NOT 0.0.0.0/0 !!
HTTPS   TCP       443   [Select: alb-security-group]  ← Traffic from ALB only
```

**Outbound Rules:**
```
Type          Protocol  Port  Destination
All traffic   All       All   0.0.0.0/0   (for updates via NAT GW)
```

⚠️ **Critical security point:** The EC2 security group source is the ALB's security group ID — not the internet. Even if someone knows your server's private IP, they cannot reach it directly.

📸 **Screenshot:** Both security groups with inbound rules clearly visible

---

## Phase 4: Create Application Load Balancer

### Step 7 — Create Target Group
1. EC2 Dashboard → Target Groups → Create Target Group
```
Target type:     Instances
Name:            private-ec2-targets
Protocol:        HTTP
Port:            80
VPC:             secure-vpc-project
Health check:    HTTP, path: /
```
2. Click Next → Don't register targets yet → Create

### Step 8 — Create Application Load Balancer
1. EC2 Dashboard → Load Balancers → Create Load Balancer → Application Load Balancer
```
Name:           secure-alb
Scheme:         Internet-facing  ← ALB must be internet-facing
IP type:        IPv4

VPC:            secure-vpc-project
Mappings:       ✅ ap-south-1a  →  Public Subnet AZ-A (10.0.1.0/24)
                ✅ ap-south-1b  →  Public Subnet AZ-B (10.0.2.0/24)

Security Groups: alb-security-group (remove default)

Listeners:
  Protocol: HTTP, Port: 80, Forward to: private-ec2-targets
```

📸 **Screenshot:** ALB configuration showing it's in the public subnets

---

## Phase 5: Create EC2 Instances in Private Subnets

### Step 9 — Create Launch Template
1. EC2 → Launch Templates → Create Launch Template
```
Name:                   private-server-template
AMI:                    Amazon Linux 2023 (free tier)
Instance type:          t2.micro (free tier)
Key pair:               Create new or use existing
Subnet:                 Don't include in template
Security group:         ec2-private-security-group
```

**Advanced Details → User Data:**
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Secure Private Server - $(hostname -f)</h1><p>This server has NO public IP. You are seeing this through the Load Balancer only.</p>" > /var/www/html/index.html
```

### Step 10 — Create Auto Scaling Group
1. EC2 → Auto Scaling Groups → Create Auto Scaling Group
```
Name:               private-ec2-asg
Launch template:    private-server-template

VPC:                secure-vpc-project
Subnets:            ✅ Private Subnet AZ-A (10.0.3.0/24)
                    ✅ Private Subnet AZ-B (10.0.4.0/24)
                    ← Private subnets ONLY

Load balancing:     Attach to existing load balancer
                    Target group: private-ec2-targets

Desired:   2
Minimum:   1
Maximum:   4
```

📸 **Screenshot:** ASG showing instances launched in private subnets with NO public IP

---

## Phase 6: Verify the Architecture

### Step 11 — Check Instances Have No Public IP
1. EC2 → Instances
2. Click on your instances
3. Verify: **Public IPv4 address: —** (empty — this is correct and intended)

📸 **Screenshot:** Instance details showing no public IP

### Step 12 — Test via Load Balancer Only
1. EC2 → Load Balancers → Copy ALB DNS name
2. Open in browser: `http://secure-alb-xxxxxxx.ap-south-1.elb.amazonaws.com`
3. You should see: "Secure Private Server - ip-10-0-3-xxx.ap-south-1.compute.internal"
4. Refresh — notice the hostname changes between 10.0.3.x and 10.0.4.x (different AZs)

📸 **Screenshot:** Browser showing the page loaded through ALB

### Step 13 — Verify Security (Try Direct Access — Should Fail)
1. Note the private IP of an EC2 instance (e.g., 10.0.3.45)
2. Try accessing http://10.0.3.45 in your browser
3. It should TIME OUT — because:
   - No public IP on the instance
   - No route from internet to private subnet
   - Security group only allows traffic from ALB

📸 **Screenshot:** Browser timing out on direct private IP access

---

## Phase 7: NACL Configuration (Additional Security Layer)

### Step 14 — Review Default NACLs
1. VPC → Network ACLs
2. Review the NACL associated with private subnets
3. Add an explicit DENY rule for unwanted traffic:

**For Private Subnet NACL — Inbound:**
```
Rule #  Type    Protocol  Port    Source        Allow/Deny
100     HTTP    TCP       80      10.0.0.0/16   ALLOW   ← From VPC only (ALB)
200     HTTPS   TCP       443     10.0.0.0/16   ALLOW   ← From VPC only
*       All     All       All     0.0.0.0/0     DENY    ← Deny everything else
```

---

## ⚠️ IMPORTANT: Cleanup After Testing

To avoid charges (especially NAT Gateway at ~$0.045/hr):
1. Delete Auto Scaling Group
2. Delete EC2 instances
3. Delete Load Balancer
4. Delete Target Group
5. Delete NAT Gateway
6. Release Elastic IP (created by NAT GW)
7. Delete VPC (this deletes subnets, IGW, route tables automatically)

**Do this immediately after taking screenshots!**
