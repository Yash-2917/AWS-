# Security Group Rules — Complete Documentation

## Security Group 1: alb-security-group
**Purpose:** Controls traffic to and from the Application Load Balancer  
**Attached to:** Application Load Balancer (in public subnets)

### Inbound Rules
| Rule # | Type  | Protocol | Port Range | Source    | Description |
|--------|-------|----------|------------|-----------|-------------|
| 1      | HTTP  | TCP      | 80         | 0.0.0.0/0 | Allow HTTP from internet |
| 2      | HTTPS | TCP      | 443        | 0.0.0.0/0 | Allow HTTPS from internet |

### Outbound Rules
| Rule # | Type        | Protocol | Port Range | Destination | Description |
|--------|-------------|----------|------------|-------------|-------------|
| 1      | All traffic | All      | All        | 0.0.0.0/0   | Allow all outbound |

**Why:** ALB must accept traffic from the entire internet (that's its purpose). But its outbound traffic will only reach EC2s because the EC2 security group restricts who can talk to it.

---

## Security Group 2: ec2-private-security-group
**Purpose:** Controls traffic to and from private EC2 instances  
**Attached to:** EC2 instances in private subnets

### Inbound Rules
| Rule # | Type  | Protocol | Port Range | Source | Description |
|--------|-------|----------|------------|--------|-------------|
| 1      | HTTP  | TCP      | 80         | sg-xxxxxxx (alb-security-group) | HTTP from ALB only |
| 2      | HTTPS | TCP      | 443        | sg-xxxxxxx (alb-security-group) | HTTPS from ALB only |

### Outbound Rules
| Rule # | Type        | Protocol | Port Range | Destination | Description |
|--------|-------------|----------|------------|-------------|-------------|
| 1      | All traffic | All      | All        | 0.0.0.0/0   | Allow updates via NAT GW |

**Why this is secure:**
- Source is the ALB security group ID — not an IP range. Even if someone spoofs an IP in the VPC range, they cannot reach the EC2 without coming through the ALB
- Port 22 (SSH) is NOT open — cannot SSH directly into servers from internet
- Outbound is open so servers can download security patches via NAT Gateway

---

## Security Group Chaining — How it Works

```
Internet → ALB (sg allows 80/443 from 0.0.0.0/0)
         → EC2 (sg allows 80/443 from ALB sg-id ONLY)
         ✗  Internet cannot reach EC2 directly — no route, no public IP, SG blocks it
```

This is called **Security Group Chaining** or **Security Group Referencing** — a powerful AWS security pattern where downstream resources only accept traffic from upstream resource's security group, not from IP addresses.

---

## What Is NOT Allowed (Explicitly)

| Blocked Traffic | Why |
|---|---|
| SSH (port 22) from internet to EC2 | No SSH rule in EC2 SG + No public IP |
| Direct HTTP to EC2 private IP from internet | Private subnet has no internet route |
| Any traffic from internet directly to private subnet | Route table points to NAT GW (outbound only) |
| RDP (port 3389) | No rule exists for it |
| Database ports (3306, 5432) | No rule — would need separate DB security group |
