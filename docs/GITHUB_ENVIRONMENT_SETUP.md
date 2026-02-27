# GitHub Environment Setup Guide

## Overview

This guide explains how to configure GitHub environments for the CDK deployment workflow. Environments provide deployment protection rules, secrets management, and environment-specific configuration.

## Prerequisites

- GitHub repository admin access
- AWS account with OIDC provider configured (see [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md))
- IAM role ARN for GitHub Actions

## Creating a GitHub Environment

### Via GitHub Web UI

1. Navigate to your repository on GitHub
2. Click **Settings** → **Environments**
3. Click **New environment**
4. Enter environment name (e.g., `dev`, `staging`, `prod`)
5. Click **Configure environment**

### Via GitHub CLI

```bash
# Create environment
gh api repos/{owner}/{repo}/environments/{environment_name} \
  --method PUT \
  --field wait_timer=0 \
  --field prevent_self_review=false
```

## Environment Naming Conventions

Use consistent naming across environments:

- **dev**: Development environment for testing changes
- **staging**: Pre-production environment for validation
- **prod**: Production environment for live deployments

## Required Environment Variables

Configure these secrets/variables for each environment:

### AWS_DEPLOYMENT_ROLE_ARN (Secret)

The ARN of the IAM role that GitHub Actions will assume via OIDC.

**Format**: `arn:aws:iam::{ACCOUNT_ID}:role/{ROLE_NAME}`

**Example**: `arn:aws:iam::123456789012:role/tr-dungeons-github-actions-role`

**How to add**:
1. In environment settings, scroll to **Environment secrets**
2. Click **Add secret**
3. Name: `AWS_DEPLOYMENT_ROLE_ARN`
4. Value: Your IAM role ARN
5. Click **Add secret**

### AWS_REGION (Variable - Optional)

The AWS region for deployment. Defaults to `us-east-1` if not specified.

**Supported regions**: Any AWS region (e.g., `us-east-1`, `us-west-2`, `eu-west-1`)

**How to add**:
1. In environment settings, scroll to **Environment variables**
2. Click **Add variable**
3. Name: `AWS_REGION`
4. Value: Your preferred region (e.g., `us-east-1`)
5. Click **Add variable**

## Environment Protection Rules

### Required Reviewers

Require manual approval before deployments (recommended for production):

1. In environment settings, check **Required reviewers**
2. Add team members or teams who can approve deployments
3. Set number of required approvals (1-6)

**Example for production**:
- Required reviewers: DevOps team, Tech lead
- Required approvals: 2

### Deployment Branches

Restrict which branches can deploy to this environment:

1. In environment settings, under **Deployment branches**, select:
   - **All branches**: Any branch can deploy (dev environments)
   - **Protected branches only**: Only protected branches (staging/prod)
   - **Selected branches**: Specific branch patterns

**Example for production**:
- Deployment branches: **Protected branches only**
- Protected branches: `main`, `release/*`

### Wait Timer

Add a delay before deployment starts (useful for last-minute cancellations):

1. In environment settings, set **Wait timer**
2. Enter delay in minutes (0-43200)

**Example for production**:
- Wait timer: 5 minutes

## Complete Environment Configuration Example

### Development Environment

```yaml
Name: dev
Protection rules:
  - Required reviewers: None
  - Deployment branches: All branches
  - Wait timer: 0 minutes

Secrets:
  - AWS_DEPLOYMENT_ROLE_ARN: arn:aws:iam::123456789012:role/tr-dungeons-github-actions-role

Variables:
  - AWS_REGION: us-east-1
```

### Production Environment

```yaml
Name: prod
Protection rules:
  - Required reviewers: DevOps team (2 approvals)
  - Deployment branches: Protected branches only
  - Wait timer: 5 minutes

Secrets:
  - AWS_DEPLOYMENT_ROLE_ARN: arn:aws:iam::987654321098:role/tr-dungeons-github-actions-role-prod

Variables:
  - AWS_REGION: us-east-1
```

## Testing the Configuration

### Test Environment Access

1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Select your environment
4. Choose action: **synth**
5. Click **Run workflow**

If configured correctly, the workflow should:
- ✅ Authenticate with AWS using OIDC
- ✅ Synthesize the CDK stack
- ✅ Display outputs in the job summary

### Verify OIDC Authentication

Check the workflow logs for:

```
Configuring AWS credentials
✅ Assumed role: arn:aws:iam::123456789012:role/tr-dungeons-github-actions-role
```

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause**: IAM role trust policy doesn't allow GitHub Actions OIDC

**Solution**: Verify the trust policy in [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md)

### Error: "Secret AWS_DEPLOYMENT_ROLE_ARN not found"

**Cause**: Secret not configured in environment

**Solution**: Add the secret following the steps above

### Error: "Environment not found"

**Cause**: Environment name mismatch between workflow input and GitHub settings

**Solution**: Ensure environment name matches exactly (case-sensitive)

### Deployment Stuck on "Waiting for approval"

**Cause**: Required reviewers protection rule is enabled

**Solution**: Approve the deployment or adjust protection rules

## Additional Resources

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS OIDC Setup Guide](AWS_OIDC_SETUP.md)
- [Deployment Workflow Usage](DEPLOYMENT_WORKFLOW.md)
