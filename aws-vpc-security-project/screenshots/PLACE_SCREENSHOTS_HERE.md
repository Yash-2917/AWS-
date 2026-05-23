# Screenshots — Place Your AWS Console Screenshots Here

Take screenshots at every step and name them clearly:

01-vpc-created.png           → VPC dashboard after creation
02-subnet-list.png           → All 4 subnets (2 public, 2 private)
03-route-table-public.png    → Public route table (IGW route)
04-route-table-private.png   → Private route table (NAT GW route)
05-alb-sg-rules.png          → ALB security group inbound rules
06-ec2-sg-rules.png          → EC2 security group (source = ALB sg-id)
07-alb-created.png           → Load balancer in public subnets
08-ec2-no-public-ip.png      → EC2 instances with NO public IP address
09-asg-running.png           → Auto Scaling Group with 2 instances
10-app-via-alb.png           → Browser showing page through ALB URL
11-direct-access-fail.png    → Browser timing out on private IP (security proof)
12-architecture-map.png      → AWS VPC resource map view
