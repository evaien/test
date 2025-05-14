# AWS Multi-Account Architecture for Innovate Inc.

To support security, scalability, and operational efficiency, I propose a multi-account AWS architecture.

1. Security & Isolation
	1. Isolate workloads based on security and operational requirements.
	2. Maintain strict separation between general operations and sensitive workloads.
	3. **Log Archive** account: Centralized repository for security, audit, and compliance teams to store logs from all accounts.
	4. **Security Tooling** account: Provides centralized delegated admin access to AWS security services, with view-only access for investigations across all accounts.
2. Access Management & Federation
	1. **Identity** account: Centralized AWS IAM Identity Center (SSO) for secure cross-account authentication and access control.
	2. **Management** account: Restricts privileged actions and enforces organizational policies.
3. Cost Management & Billing Optimization
	1. Clear visibility into expenses across teams and departments.
	2. Custom budget enforcement and spending limits for financial efficiency.
4. Networking & Multi-AZ Deployments
	1. **Networking/Shared Services** Account: Dedicated account for shared networking resources, including VPCs, AWS Transit Gateway, and AWS PrivateLink.
	2. Controlled and secure cross-account communication with strict access policies.
5. Scalability for Large Organizations
	1. AWS Organizations Integration: Policy enforcement, governance, and resource management across accounts.
	2. Simplified resource allocation across business units.
6. Disaster Recovery & Fault Tolerance
	1. Minimizes risk and blast radius in case of failures.
	2. **Backup** Account: Dedicated account for cross-region replication and disaster recovery planning.
	
## Future Expansion

Depending on CI/CD tooling, deployment strategy, and evolving business needs, Innovate Inc. can expand this architecture by introducing additional accounts to enhance operational efficiency and security.

# AWS Architecture for Innovate Inc.

**Networking/Shared Services** Account: Centralized networking resources (VPC, Transit Gateway, NAT Gateway).
**Workload** Accounts: Individual VPCs for application environments (Prod, Staging, Dev).

1. VPC Design
	1. Each workload account gets a dedicated VPC with multiple subnets: 
		Public Subnets: Hosts Load Balancer or API Gateway. 
		Private Subnets: Hosts Kubernetes nodes (EKS) and backend services. 
		Database Subnet: Dedicated for RDS with strict access controls.
2. VPC Peering OR AWS Transit Gateway connects workload accounts to the Networking Account for shared services.
3. Kubernetes Networking
	1. Service Mesh: Istio or AWS App Mesh for inter-service communication.
	1. Ingress Controller: AWS Load Balancer Controller
	2. Pod-Level Security: Network policies restrict traffic flow inside the cluster.
4. Load Balancers (NLB/ALB)
	1. Created in Workload Account inside the Public Subnet, linked to Route 53 for domain routing.
5. Firewalls
	1. AWS Network Firewall – Created in Networking Account to provide centralized security control.
6. NAT Gateways
	1. Created in Networking Account for shared outbound access, deployed in multiple AZs for failover.
    2. Each Workload Account VPC should route outbound internet traffic via Networking Account’s NAT Gateway.

## Security

1. Identity & Access Control
	1. Dedicated AWS **Identity** Account: centralizes IAM management.
		1. Uses IAM Identity Center for least privilege access.
	2. Restrict AWS Management Account Usage
		1. No workloads or unnecessary users in the management account.
		2. Limit root account access with multi-factor authentication.
2. VPC & Traffic Isolation
	1. **Networking/Shared Services** Account: Hosts core security services and controls. 
	2. **Workload** Accounts: Own their VPCs, preventing unauthorized cross-account access.
	3. AWS Transit Gateway provides secure inter-VPC communication.
	4. AWS Network Firewall filters incoming & outgoing traffic.
	5. Security Groups & NACLs restrict internal communication at the subnet and instance level.
3. Perimeter Security
	1. Internet Gateway controls ingress/egress for internet-facing applications.
	2. AWS Network Firewall protects against malicious traffic and unauthorized access.
	4. Centralized NAT Gateway routes outbound traffic securely to avoid exposing private resources.
	5. *Optional AWS Shield for DDoS Protection*
4. Secure Connectivity & PrivateLink
	1. VPC Endpoints for AWS Services: PrivateLink to prevent direct internet access to AWS services.
	2. Inter-VPC Traffic Control with Transit Gateway
	3. *Optional VPN & Direct Connect*
5. Logging, Monitoring & Threat Detection
	1. **Security Tooling** account hosts AWS Security Hub & GuardDuty
	2. **Log Archival** account stores VPC flow logs, CloudTrail, and ALB logs for security auditing.

## Kubernetes Deployment Strategy
	1. Multi-AZ EKS Deployment
	2. Dedicated Workload VPC: private subnets for app components; public subnet for ALB ingress traffic.
	3. AWS Load Balancer Controller
		1. Deploys ALB for frontend & NLB for backend services.
	4. Pod Security Policies & Network Policies
		1. Restricts inter-service communication (e.g., DB access only via backend API). 
	5. AWS Secrets Manager for managing sensitive API keys & DB credentials.
		
### Node Group Strategy

For better reliability, security, and optimized resource allocation, I propose using a dedicated managed node pool where Kubernetes system workloads and Karpenter will be running.
Karpenter is used to provision nodes for workloads running on the cluster, which will deploy a mix of On-Demand and Amazon EC2 Spot Instances.

Since x86 (32-bit) workloads are virtually obsolete, all x86-related workloads in AWS naturally run on amd64 (x86-64). 
To avoid confusion, I am not using a misleading 'x86 pool', instead consolidating provisioning into 'amd64-spot' for cost-efficient deployments and 'amd64-on-demand' for stability.

1. Graviton NodePool
	1. Instance Types: c7g.large, m7g.large, r7g.large
	2. Definition:
		`apiVersion: karpenter.k8s.aws/v1alpha1
kind: NodePool
metadata:
  name: graviton-nodepool
spec:
  template:
    spec:
      providerRef:
        name: graviton-nodeclass
      requirements:
        - key: "kubernetes.io/arch"
          operator: In
          values: ["arm64"]
        - key: "karpenter.k8s.aws/capacity-type"
          operator: In
          values: ["SPOT", "ON_DEMAND"]
      instanceTypes:
        - "c7g.large"
        - "c7g.xlarge"
        - "c7g.2xlarge"
        - "m7g.large"
        - "m7g.xlarge"
        - "m7g.2xlarge"
  limits:
    cpu: "1000"
  consolidation:
    enabled: true
`
2. AMD64 NodePool
	1. Instance Types: c5.large, m5.large, r5.large
	2. Definition:
		`apiVersion: karpenter.k8s.aws/v1alpha1
kind: NodePool
metadata:
  name: amd64-nodepool
spec:
  template:
    spec:
      providerRef:
        name: amd64-nodeclass
      requirements:
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.k8s.aws/capacity-type"
          operator: In
          values: ["SPOT", "ON_DEMAND"]
      instanceTypes:
        - "c5.large"
        - "c5.xlarge"
        - "c5.2xlarge"
        - "m5.large"
        - "m5.xlarge"
        - "m5.2xlarge"
        - "r5.large"
        - "r5.xlarge"
        - "r5.2xlarge"
  limits:
    cpu: "2000"
  consolidation:
    enabled: true
`

Now we can execute the following scenarios:

1. Pod Deployment Targeting Graviton Instances
`apiVersion: v1
kind: Pod
metadata:
  name: backend-app
spec:
  nodeSelector:
    kubernetes.io/arch: "arm64"
    karpenter.sh/capacity-type: "SPOT"
`
This ensures the workload is scheduled on Spot Graviton first. If no Spot Graviton nodes are available, Karpenter will fallback to On-Demand Graviton.

2. Pod Deployment Targeting amd64 Instances
`apiVersion: v1
kind: Pod
metadata:
  name: frontend-app
spec:
  nodeSelector:
    kubernetes.io/arch: "amd64"
    karpenter.sh/capacity-type: "SPOT"
`
This ensures the workload runs on Spot amd64 first. If no Spot amd64 nodes are available, Karpenter provisions an On-Demand amd64 instance instead.

3. Pod Deployment Allowing Flexible Fallback
`affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
            - key: "kubernetes.io/arch"
              operator: In
              values: ["arm64"]
      - weight: 50
        preference:
          matchExpressions:
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
`
This means Kubernetes prefers Graviton, but allows fallback to amd64 if no Graviton nodes exist.

### Scaling Approach
	1. Horizontal Pod Autoscaler adjusts Flask backend replicas based on CPU & memory load.
	2. Karpenter expands and shrinks the node count dynamically.
		1. Enable Karpenter TTL for Efficient Cleanup
		2. Spot-to-On-Demand Fallback: multiple instance types in each provisioner are defined to avoid scheduling failures.
	3. AWS Load Balancer Controller to auto-adjust ALB/NLB resources.
	4. Billing alarms to monitor compute spend

### Resource Allocation & Optimization
	1. Resource requests & limits for stability
	2. Pod priority classes for critical workloads

## CI/CD Pipeline: 
		1. GitOps-based Deployment (GitHub Actions / ArgoCD)
		2. AWS CodeBuild or GitHub Actions for containerizing Python Flask & React.
		3. Amazon ECR for container storage.
		4. Terraform for IaC.

## Database

Given sensetivity of data used, I recommend using Amazon RDS as a database service provider.
This gives Innovate Inc. the following benefits:

	1. Automated backups, failover, and scaling.
	2. Point-in-Time Recovery (PITR)
	2. High Availability with Multi-AZ deployment.
	3. Private subnet placement.
	4. Security groups & IAM roles – to restricts access only to authorized workloads.