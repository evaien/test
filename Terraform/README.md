### Disclaimer

Given the complexity of multi-account setup, I will not be creating TGW, subnets, attachments etc in a centralized Networking account and instead will be using a simplified setup.
As an example of multi account TGW setup with RAM, see this https://github.com/terraform-aws-modules/terraform-aws-transit-gateway/tree/master/examples/multi-account

### Terraform setup

We will be hosting Terraform administrative user in **Networking/Shared Services**.
We will be using S3 bucket for Terraform state.

## Create TerraformAdmin Role in the Shared Services Account

1. Log in to the Shared Services Account
2. IAM  -> Roles -> Create Role.
3. Select AWS Service and then IAM (as the trusted entity).
4. Set Role Name to TerraformAdmin.
5. Set trust policy
`{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<management-account-id>:root"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<identity-account-id>:saml-provider/AWSSSO"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/sso:permission-set": "AdministratorAccess"
        }
      }
    }
  ]
}`
6. Attach IAM Policy from TerraformAdmin-inline-policy.json

## Bootstrapping Terraform backend

Now that we have TerraformAdmin role we can use it to create S3 backend.

1. Configure AWS
 Example 
 `[profile identity-sso]
sso_start_url = https://your-sso-url.awsapps.com/start
sso_region    = us-east-1
sso_account_id = 111111111111 # Identity Account ID
sso_role_name = AWSAdministratorAccess # or your assigned SSO role
region        = us-east-1

[profile terraform-admin]
role_arn = arn:aws:iam::222222222222:role/TerraformAdmin # Shared Services account role
source_profile = identity-sso
region = us-east-1
`
2. Using AWS CLI login to Identity account SSO.
`aws sso login --profile identity-sso`
3. `cd backend && terraform init && terraform plan && terraform apply`

## Create TerraformExecutionRole in Workload account
This role will be used to create resources in Workload account. We will be creating it manually now, this later can be migrated to centralized IAM management.

1. Log into the Workload Account
2. Create IAM Role -> Trusted Entity: Another AWS account -> Account ID: <Shared Services Account ID> -> Name TerraformExecutionRole
3. Set trust policy
`{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<shared-services-account-id>:role/TerraformAdmin"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}`
4. Attach IAM Policy from TerraformExecutionRole-inline-policy.json
	
### Provisioning resources

Terraform configuration provided will create EKS cluster with Karpenter installed into it and create two Karpenter NodePools and EC2NodeClasses

`cd terraform-workload/prod && terraform init && terraform plan && terraform apply`