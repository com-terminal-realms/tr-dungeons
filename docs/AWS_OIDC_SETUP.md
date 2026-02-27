# AWS OIDC Setup Guide

## Overview

This guide explains how to configure AWS OpenID Connect (OIDC) authentication for GitHub Actions. OIDC allows GitHub Actions to assume AWS IAM roles without storing long-lived credentials.

## Prerequisites

- AWS account with admin access
- AWS CLI configured
- CDK CLI installed (`npm install -g aws-cdk`)
- GitHub repository: `com-terminal-realms/tr-dungeons`

## Architecture

```
GitHub Actions Workflow
    ↓ (OIDC Token)
GitHub OIDC Provider (AWS)
    ↓ (AssumeRoleWithWebIdentity)
IAM Role (tr-dungeons-github-actions-role)
    ↓ (Permissions)
AWS Resources (S3, DynamoDB, SQS, SNS, CloudFormation)
```

## CDK Bootstrap

Before deploying any CDK stacks, you must bootstrap your AWS environment.

### What is CDK Bootstrap?

CDK bootstrap creates the `CDKToolkit` CloudFormation stack, which includes:
- S3 bucket for storing CDK assets (Lambda code, Docker images)
- IAM roles for CloudFormation deployments
- ECR repository for Docker images (if needed)
- SSM parameters for configuration

### Bootstrap Command

```bash
# Bootstrap with default settings
cdk bootstrap aws://ACCOUNT-ID/REGION

# Example
cdk bootstrap aws://123456789012/us-east-1
```

### Verify Bootstrap

```bash
# Check if CDKToolkit stack exists
aws cloudformation describe-stacks \
  --stack-name CDKToolkit \
  --region us-east-1
```

### Bootstrap for Multiple Environments

If deploying to multiple AWS accounts or regions:

```bash
# Development account
cdk bootstrap aws://111111111111/us-east-1

# Production account
cdk bootstrap aws://222222222222/us-east-1
```

## OIDC Provider Setup

The OIDC provider is automatically created by the CDK stack (`BuildDistributionStack`). However, you can verify or create it manually if needed.

### Verify OIDC Provider

```bash
aws iam list-open-id-connect-providers
```

Look for: `arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com`

### Manual OIDC Provider Creation (if needed)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

## IAM Role Configuration

The IAM role is automatically created by the CDK stack with the correct trust policy and permissions.

### Trust Policy

The role trusts GitHub Actions OIDC provider with conditions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*"
        }
      }
    }
  ]
}
```

### Permissions

The role has permissions for:
- **S3**: Read/write to builds bucket
- **SQS**: Send messages to notification queue
- **DynamoDB**: Read/write to metadata table
- **CloudFormation**: Deploy CDK stacks (via CDKToolkit)

### Verify Role

```bash
# Get role details
aws iam get-role --role-name tr-dungeons-github-actions-role

# Get role ARN
aws iam get-role \
  --role-name tr-dungeons-github-actions-role \
  --query 'Role.Arn' \
  --output text
```

## Deployment Steps

### Step 1: Bootstrap CDK (One-time)

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

# Bootstrap CDK
cdk bootstrap aws://${AWS_ACCOUNT_ID}/${AWS_REGION}
```

### Step 2: Deploy BuildDistributionStack

The stack creates the OIDC provider and IAM role:

```bash
cd infrastructure/cdk

# Synthesize to verify
cdk synth

# Deploy the stack
cdk deploy --require-approval never
```

### Step 3: Get IAM Role ARN

```bash
# Get the role ARN from stack outputs
aws cloudformation describe-stacks \
  --stack-name BuildDistributionStack \
  --query 'Stacks[0].Outputs[?OutputKey==`GitHubActionsRoleArn`].OutputValue' \
  --output text
```

### Step 4: Configure GitHub Secret

Add the role ARN to GitHub environment secrets (see [GITHUB_ENVIRONMENT_SETUP.md](GITHUB_ENVIRONMENT_SETUP.md)):

1. Go to repository **Settings** → **Environments**
2. Select your environment (e.g., `dev`)
3. Add secret: `AWS_DEPLOYMENT_ROLE_ARN`
4. Value: The role ARN from Step 3

## Security Best Practices

### Principle of Least Privilege

The IAM role should only have permissions needed for deployment:
- ✅ CloudFormation stack operations
- ✅ S3 bucket access for CDK assets
- ✅ Resource creation/update/delete for stack resources
- ❌ Avoid wildcard permissions (`*`)
- ❌ Avoid admin access

### Repository Restrictions

The trust policy restricts access to specific repository:

```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*"
}
```

To restrict to specific branches:

```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:ref:refs/heads/main"
}
```

### Session Duration

The role has a maximum session duration of 1 hour:

```python
max_session_duration=Duration.hours(1)
```

Adjust if deployments take longer:

```python
max_session_duration=Duration.hours(2)
```

### Audit and Monitoring

Enable CloudTrail to audit role usage:

```bash
# View recent AssumeRole calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 10
```

## Testing OIDC Authentication

### Test from GitHub Actions

1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Select environment: `dev`
4. Select action: `synth`
5. Click **Run workflow**

Check logs for successful authentication:

```
Configuring AWS credentials
✅ Assumed role: arn:aws:iam::123456789012:role/tr-dungeons-github-actions-role
✅ Session name: github-actions-123456789
```

### Test Locally (Simulation)

You cannot test OIDC locally, but you can test with assumed role credentials:

```bash
# Assume the role manually
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-ID:role/tr-dungeons-github-actions-role \
  --role-session-name test-session

# Use the temporary credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# Test CDK operations
cd infrastructure/cdk
cdk synth
```

## Troubleshooting

### Error: "User is not authorized to perform: sts:AssumeRoleWithWebIdentity"

**Cause**: Trust policy doesn't allow GitHub Actions

**Solution**: Verify trust policy includes correct repository:

```bash
aws iam get-role \
  --role-name tr-dungeons-github-actions-role \
  --query 'Role.AssumeRolePolicyDocument'
```

### Error: "No OpenIDConnect provider found"

**Cause**: OIDC provider not created

**Solution**: Deploy the BuildDistributionStack or create provider manually

### Error: "CDKToolkit stack not found"

**Cause**: CDK not bootstrapped

**Solution**: Run `cdk bootstrap` command

### Error: "Access Denied" during deployment

**Cause**: IAM role lacks necessary permissions

**Solution**: Verify role has CloudFormation and resource permissions

### Error: "Invalid identity token"

**Cause**: GitHub OIDC token expired or invalid

**Solution**: Re-run the workflow (tokens are short-lived)

## Additional Resources

- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [CDK Bootstrap Documentation](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping.html)
- [GitHub Environment Setup](GITHUB_ENVIRONMENT_SETUP.md)
- [Deployment Workflow Usage](DEPLOYMENT_WORKFLOW.md)
