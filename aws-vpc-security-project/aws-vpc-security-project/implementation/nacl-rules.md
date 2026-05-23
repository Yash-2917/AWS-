# Network ACL (NACL) Configuration

## What is a NACL?
A Network ACL is a stateless firewall that operates at the SUBNET level.
Unlike Security Groups (which are stateful), NACLs must explicitly allow BOTH inbound AND outbound traffic.

---

## Public Subnet NACL

### Inbound Rules
| Rule # | Type  | Protocol | Port  | Source    | Action |
|--------|-------|----------|-------|-----------|--------|
| 100    | HTTP  | TCP      | 80    | 0.0.0.0/0 | ALLOW  |
| 110    | HTTPS | TCP      | 443   | 0.0.0.0/0 | ALLOW  |
| 120    | Custom| TCP      | 1024–65535 | 0.0.0.0/0 | ALLOW |
| *      | All   | All      | All   | 0.0.0.0/0 | DENY   |

> Rule 120 allows ephemeral (return) ports. NACLs are stateless — return traffic must be explicitly allowed.

### Outbound Rules
| Rule # | Type  | Protocol | Port  | Destination | Action |
|--------|-------|----------|-------|-------------|--------|
| 100    | HTTP  | TCP      | 80    | 0.0.0.0/0   | ALLOW  |
| 110    | HTTPS | TCP      | 443   | 0.0.0.0/0   | ALLOW  |
| 120    | Custom| TCP      | 1024–65535 | 0.0.0.0/0 | ALLOW |
| *      | All   | All      | All   | 0.0.0.0/0   | DENY   |

---

## Private Subnet NACL

### Inbound Rules
| Rule # | Type  | Protocol | Port  | Source      | Action |
|--------|-------|----------|-------|-------------|--------|
| 100    | HTTP  | TCP      | 80    | 10.0.0.0/16 | ALLOW  |
| 110    | Custom| TCP      | 1024–65535 | 0.0.0.0/0 | ALLOW |
| *      | All   | All      | All   | 0.0.0.0/0   | DENY   |

> Source for HTTP is 10.0.0.0/16 (VPC only) — not the whole internet.

### Outbound Rules
| Rule # | Type  | Protocol | Port  | Destination | Action |
|--------|-------|----------|-------|-------------|--------|
| 100    | HTTP  | TCP      | 80    | 0.0.0.0/0   | ALLOW  |
| 110    | HTTPS | TCP      | 443   | 0.0.0.0/0   | ALLOW  |
| 120    | Custom| TCP      | 1024–65535 | 0.0.0.0/0 | ALLOW |
| *      | All   | All      | All   | 0.0.0.0/0   | DENY   |

---

## Key Difference: Security Group vs NACL in This Project

```
Internet Request → NACL (subnet check) → Security Group (instance check) → EC2
```

Both must PASS for traffic to reach the server. Either one failing blocks access.

- If NACL blocks a port, Security Group never even sees the traffic
- If NACL allows it but Security Group doesn't → still blocked
- Double protection on every packet
