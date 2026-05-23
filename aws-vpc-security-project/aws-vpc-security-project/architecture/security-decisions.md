# Security Architecture Decisions — WHY We Made These Choices

> This document explains the reasoning behind every security decision in the project.
> This is what separates a student who "followed a tutorial" from one who "understands architecture."

---

## Decision 1: Why a Custom VPC instead of Default VPC?

**What we did:** Created a custom VPC (10.0.0.0/16) instead of using AWS's default VPC.

**Why:**
- Default VPC has all subnets public by default — a security anti-pattern
- Custom VPC gives full control over IP ranges, subnet design, and routing
- In companies, default VPCs are never used in production
- A custom VPC allows the public/private separation that is the core of this project

**Security principle:** *Secure by design, not by accident.*

---

## Decision 2: Why /16 for VPC and /24 for Subnets?

**CIDR Design:**
```
VPC:              10.0.0.0/16   → 65,536 IP addresses (plenty of room to grow)
Public Subnet AZ-A:  10.0.1.0/24   → 256 IPs
Public Subnet AZ-B:  10.0.2.0/24   → 256 IPs
Private Subnet AZ-A: 10.0.3.0/24   → 256 IPs
Private Subnet AZ-B: 10.0.4.0/24   → 256 IPs
```

**Why /16 for VPC:**
- Large enough to accommodate future subnets without redesigning
- Follows AWS best practice for production VPCs

**Why /24 for subnets:**
- 256 IPs per subnet is enough for a college project
- In production, private subnets are usually /20 or larger (4096 IPs) for scale

---

## Decision 3: Why Put Only the Load Balancer in the Public Subnet?

**What we did:** ALB nodes go in public subnets. EC2 servers go in PRIVATE subnets only.

**Why:**
- The Load Balancer's job is to receive internet traffic and forward it — it MUST be public
- Application servers have no business being directly reachable from the internet
- If a hacker finds a vulnerability in your app, they cannot directly access the server because it has no public IP
- They would have to first compromise the ALB, then the Security Groups — two separate barriers

**Real-world analogy:** 
Think of a bank. The front desk (public subnet) faces customers. The vault (private subnet) is in the back. Customers talk to the front desk — they never get direct access to the vault.

---

## Decision 4: Why NAT Gateway Instead of Making Servers Public?

**The problem:** Private subnet servers need to download OS updates, security patches, and software — they need outbound internet access.

**Bad solution:** Make the servers public — this defeats the purpose of a private subnet.

**Our solution:** NAT Gateway in the PUBLIC subnet. It allows:
- ✅ Outbound traffic: Private server → NAT GW → Internet (to download updates)
- ❌ Inbound traffic: Internet → NAT GW → Private server (BLOCKED — NAT GW doesn't allow this)

**Security benefit:** Servers can pull security patches (critical for security!) but are completely unreachable from the outside world.

**Cost note:** NAT Gateway costs ~$0.045/hour. Always terminate after testing to avoid charges.

---

## Decision 5: Security Groups vs NACLs — Why Both?

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance level | Subnet level |
| State | Stateful (tracks connections) | Stateless (each packet checked) |
| Rules | Allow only | Allow + Deny |
| Evaluation | All rules evaluated | Rules evaluated in order (lowest first) |

**Why we use BOTH:**

Security Groups alone are sufficient for most cases. But NACLs add a second layer:
- If someone misconfigures a Security Group (opens port 22 to 0.0.0.0/0), a NACL can block it at subnet level
- NACLs can explicitly DENY specific IPs (Security Groups cannot deny — only allow)
- Together they implement "Defense in Depth"

**Our Security Group rules:**

ALB Security Group:
- Inbound: Port 80 (HTTP) from 0.0.0.0/0 ← Allow all internet
- Inbound: Port 443 (HTTPS) from 0.0.0.0/0 ← Allow all internet
- Outbound: All traffic to Private SG only

EC2 Security Group (Private):
- Inbound: Port 80/443 from ALB Security Group ID ONLY ← Not from 0.0.0.0/0, specifically from ALB
- Outbound: All traffic (for updates via NAT GW)
- ❌ NO port 22 (SSH) open from internet

---

## Decision 6: Why Multi-AZ Deployment?

**What we did:** Subnets and EC2s in two Availability Zones (AZ-1a and AZ-1b).

**Why (security angle, not just availability):**
- Single AZ = single point of failure = potential DoS (Denial of Service) vulnerability
- Multi-AZ means an attacker cannot take down your service by targeting one data centre
- Also required for ALB — a Load Balancer needs at least 2 AZs to function properly

---

## Decision 7: Why Auto Scaling Group (ASG)?

**Security benefit beyond scaling:**
- If an EC2 instance is compromised, ASG can terminate and replace it automatically
- Health checks detect abnormal behaviour and restart instances
- Ensures minimum number of healthy instances always running

---

## Decision 8: IAM Role for EC2 — Least Privilege

**What we did:** Attached an IAM Role to EC2 instances with only the permissions they actually need.

**Why NOT use root access or access keys on the server:**
- Access keys stored on servers = major security risk (if the key leaks, attacker gets full account access)
- IAM Roles are temporary, automatically rotated credentials — no static keys stored anywhere
- Principle: give each resource the MINIMUM permission it needs to do its job, nothing more

---

## Summary: The Security Layers

```
Layer 1: VPC boundary          — Custom isolated network
Layer 2: Subnet separation     — Public vs Private
Layer 3: Route Tables          — Control where traffic can flow
Layer 4: NACLs                 — Subnet-level firewall (stateless)
Layer 5: Security Groups       — Instance-level firewall (stateful)
Layer 6: NAT Gateway           — Outbound-only internet for private servers
Layer 7: IAM Roles             — Least privilege for server permissions
Layer 8: ALB                   — Only entry point from internet
```

**This is Defense in Depth** — an attacker would have to break through 8 independent security layers to reach your servers.
