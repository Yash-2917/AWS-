# 🔐 AWS Secure VPC Architecture — 2-Tier Public/Private Network Design

> **College Minor Project | Cloud Security Architecture**  
> Based on production-grade AWS infrastructure patterns | Guided by Abhishek Veeramalla (YouTube)

---

## 📌 Project Overview

This project demonstrates a **secure, production-ready AWS Virtual Private Cloud (VPC) architecture** that separates public-facing resources from private backend servers — a design used by companies like Netflix, Amazon, and Zomato to protect their cloud infrastructure.

The core security principle: **your application servers should NEVER be directly accessible from the internet.** Only the Load Balancer sits in the public subnet. Servers live in a private subnet with no public IP address.

---

## 🎯 Security Goals Achieved

| Security Objective | Implementation |
|---|---|
| Isolate application servers from internet | Private subnet with no public IP |
| Control inbound/outbound traffic | Security Groups + NACLs |
| Allow servers to get updates safely | NAT Gateway (outbound only) |
| Distribute traffic securely | Application Load Balancer (public subnet) |
| High availability | Multi-AZ deployment (2 Availability Zones) |
| Least privilege access | IAM roles with minimum required permissions |

---

## 🏗️ Architecture Overview

```
Internet
    │
    ▼
Internet Gateway (IGW)
    │
    ▼
┌─────────────────────────────────────────────────────┐
│                  VPC (10.0.0.0/16)                  │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │           PUBLIC SUBNET LAYER               │   │
│  │                                             │   │
│  │  ┌──────────────┐   ┌──────────────┐       │   │
│  │  │ Public Sub   │   │ Public Sub   │       │   │
│  │  │ AZ-1a        │   │ AZ-1b        │       │   │
│  │  │ 10.0.1.0/24  │   │ 10.0.2.0/24  │       │   │
│  │  │              │   │              │       │   │
│  │  │ [ALB Node]   │   │ [ALB Node]   │       │   │
│  │  │ [NAT GW]     │   │              │       │   │
│  │  └──────────────┘   └──────────────┘       │   │
│  └─────────────────────────────────────────────┘   │
│                        │                            │
│            (ALB forwards traffic)                   │
│                        │                            │
│  ┌─────────────────────────────────────────────┐   │
│  │           PRIVATE SUBNET LAYER              │   │
│  │                                             │   │
│  │  ┌──────────────┐   ┌──────────────┐       │   │
│  │  │ Private Sub  │   │ Private Sub  │       │   │
│  │  │ AZ-1a        │   │ AZ-1b        │       │   │
│  │  │ 10.0.3.0/24  │   │ 10.0.4.0/24  │       │   │
│  │  │              │   │              │       │   │
│  │  │ [EC2 Server] │   │ [EC2 Server] │       │   │
│  │  │ NO PUBLIC IP │   │ NO PUBLIC IP │       │   │
│  │  └──────────────┘   └──────────────┘       │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
aws-vpc-security-project/
│
├── README.md                        ← You are here
│
├── architecture/
│   ├── architecture-diagram.png     ← Hand-drawn/AWS exported diagram
│   └── security-decisions.md        ← WHY each security decision was made
│
├── implementation/
│   ├── step-by-step-guide.md        ← Full implementation steps
│   ├── security-group-rules.md      ← All SG rules documented
│   ├── nacl-rules.md                ← NACL configuration
│   └── iam-roles.md                 ← IAM permissions used
│
├── terraform/
│   ├── main.tf                      ← Entire infrastructure as code
│   ├── variables.tf                 ← Input variables
│   ├── outputs.tf                   ← Output values
│   └── terraform.tfvars.example     ← Sample variables file
│
├── screenshots/
│   └── (place your AWS console screenshots here)
│
└── docs/
    ├── project-report.md            ← College submission report
    └── interview-answers.md         ← Common interview Q&A for this project
```

---

## 🧰 AWS Services Used

- **Amazon VPC** — Custom isolated network
- **Public & Private Subnets** — Layer separation
- **Internet Gateway (IGW)** — Internet access for public subnet
- **NAT Gateway** — Outbound-only internet for private subnet
- **Application Load Balancer (ALB)** — Traffic distribution
- **Auto Scaling Group (ASG)** — High availability
- **EC2 Instances** — Application servers
- **Security Groups** — Instance-level firewall
- **Network ACLs (NACLs)** — Subnet-level firewall
- **Route Tables** — Traffic routing rules
- **IAM Roles** — Least privilege permissions

---

## 🔑 Key Security Concepts Demonstrated

### 1. Defense in Depth
Two layers of security — Security Groups (stateful) AND NACLs (stateless) — so even if one is misconfigured, the other acts as a safety net.

### 2. Principle of Least Privilege
EC2 instances have NO public IP. NAT Gateway allows outbound traffic (for OS updates) but blocks all inbound. Zero direct internet exposure.

### 3. Network Segmentation
Public-facing components (Load Balancer) are physically separated from backend servers at the subnet level. A compromise of the public layer cannot directly reach private servers.

### 4. High Availability Security
Multi-AZ deployment ensures that if one Availability Zone goes down, traffic automatically routes to the other — preventing downtime-based attacks.

---

## 🚀 How to Reproduce This Project

See [`implementation/step-by-step-guide.md`](implementation/step-by-step-guide.md) for full instructions.

**Time required:** 2–3 hours on AWS Free Tier  
**Cost:** ~$0 if torn down within Free Tier limits (NAT Gateway has a small cost — terminate after testing)  
**Prerequisites:** AWS account (free tier), basic AWS console knowledge

---

## 🎓 What I Learned

1. How companies actually isolate their infrastructure in production
2. Difference between Security Groups (stateful, instance-level) and NACLs (stateless, subnet-level)
3. Why NAT Gateway is critical — servers need to reach the internet for updates, but the internet must NOT reach the servers
4. How to design CIDR blocks for a scalable VPC
5. How Auto Scaling Groups distribute load across Availability Zones for both availability and security

---

## 📚 Reference

- **Tutorial Video:** [Abhishek Veeramalla — AWS VPC Project](https://www.youtube.com/watch?v=FZPTL_kNvXc)
- **AWS Official Docs:** [VPC with Public and Private Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html)
- **GitHub (Channel Repo):** [iam-veeramalla/aws-devops-zero-to-hero](https://github.com/iam-veeramalla/aws-devops-zero-to-hero)

---

*Project by: [Your Name] | [Your College] | [Branch] | [Year]*
