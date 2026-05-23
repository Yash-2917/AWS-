# Interview Q&A — AWS Secure VPC Architecture Project

> These are the EXACT questions you will be asked when you present this project.
> Read these until you can answer without looking.

---

## Basic Questions

**Q: What is a VPC and why did you create a custom one?**
A: VPC (Virtual Private Cloud) is a logically isolated network in AWS. I created a custom VPC with CIDR 10.0.0.0/16 instead of using the default VPC because the default VPC has all subnets public by default, which is a security risk. A custom VPC gives full control over subnet design, routing, and isolation.

---

**Q: Why do your EC2 instances have no public IP?**
A: That's the core security design. Application servers should never be directly reachable from the internet. If they have no public IP and sit in a private subnet with no internet route, an attacker physically cannot reach them directly — even if they know the private IP. The only way to reach the servers is through the Application Load Balancer, which acts as a single, controlled entry point.

---

**Q: If servers have no internet access, how do they download security updates?**
A: Through the NAT Gateway. NAT Gateway sits in the public subnet and allows outbound-only internet access — private servers can send requests out (to download updates, patches) but the internet cannot send unsolicited traffic in. It's a one-way door.

---

**Q: What's the difference between a Security Group and a NACL?**
A: 

| Security Group | NACL |
|---|---|
| Instance level | Subnet level |
| Stateful — if you allow inbound, return traffic auto allowed | Stateless — must explicitly allow both inbound AND outbound |
| Allow rules only | Allow AND Deny rules |
| All rules evaluated together | Rules evaluated in order (lowest rule # first) |

I use both for Defense in Depth — if one is misconfigured, the other is a safety net.

---

**Q: Why did you use Security Group referencing instead of IP addresses for EC2?**
A: Rather than allowing traffic from a CIDR range (like 10.0.0.0/16), I referenced the ALB's security group ID as the source. This means only traffic that actually passed through the ALB is allowed — not just any resource in the VPC range. It's more precise and prevents lateral movement if another resource in the VPC is compromised.

---

**Q: What is the purpose of the Application Load Balancer?**
A: Three purposes: (1) It's the single entry point from the internet — centralising traffic control. (2) It distributes traffic across both EC2 instances in different AZs, preventing any single instance from becoming overwhelmed. (3) It performs health checks — if an EC2 becomes unhealthy, ALB stops sending traffic to it automatically.

---

**Q: Why did you deploy across 2 Availability Zones?**
A: High availability AND security. A single AZ is a single point of failure. If an AZ goes down (power, network, natural disaster), the entire app goes down — which is a Denial of Service situation. Multi-AZ ensures the app stays up even if one AZ fails completely.

---

## Deeper Questions (for good interviewers)

**Q: What happens if I try to SSH into your EC2 instance directly?**
A: It would fail for three reasons: (1) The instance has no public IP — no route to reach it. (2) The private subnet's route table has no route to the internet gateway — only to the NAT gateway. (3) The security group has no port 22 open from any source. To SSH into it in production, you'd use AWS Systems Manager Session Manager — which doesn't require port 22 at all.

---

**Q: How would you add a database to this architecture?**
A: I'd add a third tier — a Data Subnet, even more private than the application subnet. The DB security group would only allow traffic from the EC2 security group on the database port (3306 for MySQL). The DB would have no NAT Gateway access either. This creates a 3-tier architecture: Public (ALB) → Private App (EC2) → Private Data (RDS).

---

**Q: What is the cost implication of this architecture?**
A: The main cost is the NAT Gateway (~$0.045/hour + data transfer). In this project I used one NAT Gateway in AZ-A for cost saving. In production, you'd use one per AZ (~$0.09/hour) to avoid single point of failure on the NAT GW itself. EC2 t2.micro and ALB basic usage falls under AWS Free Tier.

---

**Q: How does this architecture handle a DDoS attack?**
A: Partially — the ALB has basic DDoS protection through AWS Shield Standard (free, automatic). For full DDoS protection, you'd add AWS Shield Advanced and AWS WAF (Web Application Firewall) in front of the ALB to filter malicious traffic before it reaches the load balancer. That would be the next enhancement to this project.

---

**Q: What would you improve in this architecture for production?**
A: Several things:
1. Add HTTPS (port 443) with an SSL certificate from AWS Certificate Manager
2. Add AWS WAF in front of ALB to filter SQL injection, XSS attacks
3. Enable AWS Config rules to detect security misconfigurations automatically
4. Enable VPC Flow Logs to CloudWatch for network traffic monitoring
5. Add a Bastion Host or use SSM Session Manager instead of opening SSH
6. Use NAT Gateway per AZ for high availability
7. Add RDS in a separate data subnet for the database layer

---

## One-Liner Answers (for rapid-fire rounds)

- **What is a CIDR block?** — IP address range notation. 10.0.0.0/16 means 65,536 possible IPs starting from 10.0.0.0.
- **What is an Elastic IP?** — A static public IP in AWS. NAT Gateway needs one so its outbound IP doesn't change.
- **What is an Internet Gateway?** — The AWS component that connects a VPC to the internet. Without it, nothing in the VPC can reach the internet.
- **What does "stateful" mean for Security Groups?** — It tracks connections. If you allow inbound traffic on port 80, the return traffic is automatically allowed without an explicit outbound rule.
- **What is Auto Scaling Group?** — Automatically adjusts the number of EC2 instances based on load. Ensures minimum instances always running for availability.
