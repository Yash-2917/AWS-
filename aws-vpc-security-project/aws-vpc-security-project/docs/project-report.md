# Project Report
## AWS Secure VPC Architecture — 2-Tier Public/Private Network Design

**Student Name:** [Your Name]  
**Roll Number:** [Your Roll No]  
**Branch:** [Your Branch]  
**College:** [Your College]  
**Subject:** Cloud Computing / Network Security  
**Academic Year:** 2025–26  

---

## Abstract

This project implements a production-grade, secure cloud network architecture on Amazon Web Services (AWS) that physically separates internet-facing resources from backend application servers. The architecture demonstrates core cloud security principles including network segmentation, defense in depth, least privilege access, and high availability. The project uses zero application code — all security is implemented through AWS infrastructure configuration: Virtual Private Cloud design, Security Groups, Network Access Control Lists, Application Load Balancer, and Auto Scaling Groups.

---

## 1. Introduction

### 1.1 Problem Statement
Organizations hosting applications on cloud platforms face significant security risks when all infrastructure is placed in a single, flat network accessible from the internet. A direct-access architecture allows attackers to target application servers without any intermediate barriers.

### 1.2 Objective
Design and implement a two-tier, security-hardened AWS VPC architecture where:
- Application servers are completely isolated from direct internet access
- All inbound traffic passes through a single, controlled entry point
- Multiple independent security layers are enforced (Defense in Depth)
- Infrastructure is resilient across multiple geographic zones

---

## 2. Architecture Design

### 2.1 Network Design
The VPC (10.0.0.0/16) is divided into two tiers:

**Public Tier:**
- 2 Public Subnets (10.0.1.0/24 and 10.0.2.0/24) across 2 Availability Zones
- Hosts: Application Load Balancer, NAT Gateway
- Has direct route to Internet Gateway

**Private Tier:**
- 2 Private Subnets (10.0.3.0/24 and 10.0.4.0/24) across 2 Availability Zones
- Hosts: EC2 Application Servers (NO public IP)
- Route to NAT Gateway only (outbound internet — no inbound)

### 2.2 Traffic Flow
```
User → Internet → Internet Gateway → ALB (public subnet) → EC2 (private subnet)
                                                    ↑ Only entry point
EC2 → NAT Gateway → Internet (for updates only — no inbound possible)
```

---

## 3. Security Controls Implemented

### 3.1 Network Segmentation
Physical separation of public and private resources at the subnet level prevents lateral movement between tiers.

### 3.2 Security Groups (Instance-level Firewall)
- ALB Security Group: Accepts only HTTP (80) and HTTPS (443) from internet
- EC2 Security Group: Accepts traffic ONLY from ALB security group ID (not IP ranges)
- No port 22 (SSH) open from internet on any resource

### 3.3 Network ACLs (Subnet-level Firewall)
Additional stateless firewall layer at the subnet boundary. Provides explicit DENY capability that Security Groups lack.

### 3.4 NAT Gateway
Enables private servers to pull security patches and updates from the internet (outbound) while being completely unreachable inbound.

### 3.5 IAM Roles
EC2 instances use IAM Roles with least-privilege permissions. No static access keys stored on servers.

---

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| Amazon VPC | Custom isolated network |
| AWS Subnets | Network segmentation |
| Internet Gateway | VPC internet connectivity |
| NAT Gateway | Outbound-only internet for private resources |
| Application Load Balancer | Traffic distribution and single entry point |
| Auto Scaling Group | High availability and fault tolerance |
| Security Groups | Instance-level stateful firewall |
| Network ACLs | Subnet-level stateless firewall |
| Route Tables | Traffic routing control |
| IAM Roles | Least privilege access management |
| Terraform (optional) | Infrastructure as Code deployment |

---

## 5. Results and Verification

### 5.1 Test 1 — Application Access via Load Balancer
- **Input:** HTTP request to ALB DNS name
- **Expected:** Page loads from private EC2 instance
- **Result:** ✅ Page loaded successfully, hostname shows private IP (10.0.3.x or 10.0.4.x)

### 5.2 Test 2 — Direct Server Access Blocked
- **Input:** HTTP request directly to EC2 private IP (10.0.3.x)
- **Expected:** Connection timeout
- **Result:** ✅ Connection timed out — server unreachable directly

### 5.3 Test 3 — High Availability
- **Input:** Terminate one EC2 instance manually
- **Expected:** Traffic continues on other instance, ASG launches replacement
- **Result:** ✅ No downtime, replacement instance launched within 3 minutes

### 5.4 Test 4 — Outbound Internet from Private Server
- **Input:** Run `curl google.com` from private EC2 (via SSM)
- **Expected:** Successful response (via NAT Gateway)
- **Result:** ✅ Response received — outbound works, inbound blocked

---

## 6. Security Principles Applied

1. **Defense in Depth** — 8 independent security layers
2. **Principle of Least Privilege** — IAM roles with minimum permissions, no root access
3. **Network Segmentation** — Public/private tier separation
4. **Zero Direct Access** — No public IP on servers, no open SSH from internet
5. **High Availability** — Multi-AZ eliminates single point of failure
6. **Immutable Infrastructure** — ASG replaces unhealthy instances automatically

---

## 7. Limitations and Future Enhancements

| Current Limitation | Planned Enhancement |
|---|---|
| HTTP only | Add HTTPS with AWS Certificate Manager SSL |
| No WAF | Add AWS WAF for SQL injection / XSS protection |
| No monitoring | Add VPC Flow Logs + CloudWatch alerts |
| No threat detection | Add AWS GuardDuty for ML-based threat detection |
| SSH not configured | Use AWS Systems Manager Session Manager (no port 22 needed) |
| Single-region | Multi-region with Route 53 failover |

---

## 8. Conclusion

This project successfully demonstrates a production-grade cloud security architecture that isolates application servers from direct internet exposure while maintaining full functionality and high availability. The architecture implements multiple independent security controls that collectively provide robust protection against common cloud attack vectors including unauthorized direct access, lateral movement, and single-point-of-failure exploitation.

The skills demonstrated — VPC design, security group architecture, IAM configuration, and network segmentation — are directly applicable to cloud security roles and represent patterns used by major enterprises in production today.

---

## References

1. Abhishek Veeramalla, "AWS VPC Public Private Subnet Configuration," YouTube, 2023. [https://www.youtube.com/watch?v=FZPTL_kNvXc](https://www.youtube.com/watch?v=FZPTL_kNvXc)
2. AWS Documentation, "VPC with Public and Private Subnets," Amazon Web Services. [https://docs.aws.amazon.com/vpc/latest/userguide/](https://docs.aws.amazon.com/vpc/latest/userguide/)
3. AWS Documentation, "Security Groups," Amazon EC2. [https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)
4. iam-veeramalla, "aws-devops-zero-to-hero," GitHub. [https://github.com/iam-veeramalla/aws-devops-zero-to-hero](https://github.com/iam-veeramalla/aws-devops-zero-to-hero)
