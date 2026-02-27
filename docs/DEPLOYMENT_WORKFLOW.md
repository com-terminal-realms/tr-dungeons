# Deployment Workflow Usage Guide

## Overview

This guide explains how to use the GitHub Actions workflow to deploy CDK infrastructure for the TR-Dungeons build distribution system.

## Prerequisites

Before using the deployment workflow, ensure:

- ✅ AWS account is bootstrapped with CDK (see [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md))
- ✅ GitHub environments are configured (see [GITHUB_ENVIRONMENT_SETUP.md](GITHUB_ENVIRONMENT_SETUP.md))
- ✅ OIDC provider and IAM role are deployed
- ✅ `AWS_DEPLOYMENT_ROLE_ARN` secret is set in GitHub environment

## Workflow Actions

The workflow supports three actions:

### 1. Synth (Synthesize)

Generates CloudFormation templates without deploying.

**Use cases**:
- Verify CDK code compiles correctly
- Review generated CloudFormation templates
- Test changes before deployment

**Command**:
1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Environment: Select your environment (e.g., `dev`)
4. Action: Select **synth**
5. Click **Run workflow**

**Output**: CloudFormation template displayed in logs

### 2. Diff (Show Changes)

Compares current infrastructure with proposed changes.

**Use cases**:
- Review what will change before deploying
- Identify resource additions, modifications, deletions
- Verify no unexpected changes

**Command**:
1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Environment: Select your environment
4. Action: Select **diff**
5. Click **Run workflow**

**Output**: Diff report showing:
- ➕ Resources to be added (green)
- 🔄 Resources to be modified (yellow)
- ➖ Resources to be deleted (red)

### 3. Deploy

Deploys infrastructure changes to AWS.

**Use cases**:
- Deploy new infrastructure
- Update existing resources
- Apply configuration changes

**Command**:
1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Environment: Select your environment
4. Action: Select **deploy**
5. Click **Run workflow**

**Output**: 
- Deployment progress logs
- Stack outputs (bucket name, queue URL, etc.)
- Deployment artifacts

## Workflow Stages

Each workflow run executes these stages:

### 1. Input Validation

Validates workflow inputs:
- Environment name is not empty
- Action is one of: synth, diff, deploy

**Failure**: Workflow stops if validation fails

### 2. Test Suite

Runs comprehensive tests:
- **pytest**: Unit tests for CDK stack
- **black**: Code formatting check
- **ruff**: Linting checks
- **mypy**: Type checking

**Failure**: Workflow stops if any test fails

### 3. AWS Authentication

Authenticates with AWS using OIDC:
- Assumes IAM role via OIDC token
- No long-lived credentials stored
- Session valid for 1 hour

**Failure**: Workflow stops if authentication fails

### 4. CDK Bootstrap Check

Verifies CDK is bootstrapped:
- Checks for `CDKToolkit` stack
- Displays bootstrap status

**Failure**: Workflow stops if bootstrap missing

### 5. CDK Operation

Executes selected action (synth/diff/deploy):
- Runs CDK command with environment context
- Displays results in logs and summary

**Failure**: Workflow stops if CDK operation fails

### 6. Output Capture (Deploy only)

Captures and displays stack outputs:
- S3 bucket name
- SQS queue URL
- SNS topic ARN
- DynamoDB table name
- IAM role ARN

**Artifacts**: `outputs.json` uploaded for 30 days

## Example Workflows

### First-Time Deployment

```bash
# Step 1: Verify CDK code compiles
Action: synth
Environment: dev

# Step 2: Review what will be created
Action: diff
Environment: dev

# Step 3: Deploy infrastructure
Action: deploy
Environment: dev
```

### Updating Infrastructure

```bash
# Step 1: Review changes
Action: diff
Environment: dev

# Step 2: Deploy if changes look good
Action: deploy
Environment: dev
```

### Production Deployment

```bash
# Step 1: Test in dev first
Action: deploy
Environment: dev

# Step 2: Review prod changes
Action: diff
Environment: prod

# Step 3: Deploy to prod (requires approval)
Action: deploy
Environment: prod
# → Wait for required reviewers to approve
# → Deployment proceeds after approval
```

## Reading Workflow Outputs

### Synth Output

```
✅ Template synthesized successfully

Resources:
  - AWS::S3::Bucket (BuildsBucket)
  - AWS::SQS::Queue (NotificationQueue)
  - AWS::SNS::Topic (NotificationTopic)
  - AWS::DynamoDB::Table (MetadataTable)
  - AWS::IAM::Role (GitHubActionsRole)
```

### Diff Output

```
Stack: BuildDistributionStack
Resources
[+] AWS::S3::Bucket BuildsBucket (new resource)
[~] AWS::DynamoDB::Table MetadataTable (modified)
 └─ [~] PointInTimeRecoveryEnabled: false → true
[-] AWS::Logs::LogGroup OldLogGroup (will be deleted)
```

**Legend**:
- `[+]` = Resource will be created
- `[~]` = Resource will be modified
- `[-]` = Resource will be deleted
- `[ ]` = No change

### Deploy Output

```
## Deployment Outputs

- **S3 Bucket**: `tr-dungeons-builds`
- **SQS Queue URL**: `https://sqs.us-east-1.amazonaws.com/123456789012/tr-dungeons-build-notifications`
- **SNS Topic ARN**: `arn:aws:sns:us-east-1:123456789012:tr-dungeons-build-releases`
- **DynamoDB Table**: `tr-dungeons-build-metadata`
- **IAM Role ARN**: `arn:aws:iam::123456789012:role/tr-dungeons-github-actions-role`

## Deployment Summary

- **Environment**: dev
- **Action**: deploy
- **Region**: us-east-1
- **Stack**: BuildDistributionStack
- **Status**: success
```

## Troubleshooting

### Workflow Fails at Input Validation

**Error**: "Environment input is required"

**Solution**: Ensure you selected an environment when running the workflow

---

**Error**: "Action must be one of: synth, diff, deploy"

**Solution**: Select a valid action from the dropdown

### Workflow Fails at Test Suite

**Error**: "pytest tests failed"

**Solution**: 
1. Run tests locally: `cd infrastructure/cdk && pytest tests/`
2. Fix failing tests
3. Commit and push changes
4. Re-run workflow

---

**Error**: "black formatting check failed"

**Solution**:
1. Format code: `cd infrastructure/cdk && black .`
2. Commit changes
3. Re-run workflow

---

**Error**: "ruff linting failed"

**Solution**:
1. Fix linting issues: `cd infrastructure/cdk && ruff check . --fix`
2. Commit changes
3. Re-run workflow

### Workflow Fails at AWS Authentication

**Error**: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Solution**: Verify OIDC setup in [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md)

---

**Error**: "Secret AWS_DEPLOYMENT_ROLE_ARN not found"

**Solution**: Add secret to GitHub environment (see [GITHUB_ENVIRONMENT_SETUP.md](GITHUB_ENVIRONMENT_SETUP.md))

### Workflow Fails at CDK Bootstrap Check

**Error**: "CDKToolkit stack not found"

**Solution**: Bootstrap CDK in your AWS account:

```bash
cdk bootstrap aws://ACCOUNT-ID/us-east-1
```

See [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md) for details.

### Workflow Fails at CDK Deploy

**Error**: "Stack is in UPDATE_ROLLBACK_COMPLETE state"

**Solution**: Delete the failed stack and redeploy:

```bash
aws cloudformation delete-stack --stack-name BuildDistributionStack
# Wait for deletion to complete
# Re-run workflow with action: deploy
```

---

**Error**: "Resource already exists"

**Solution**: Resource name conflict. Either:
1. Delete the existing resource manually
2. Update CDK code to use a different name
3. Import the existing resource into the stack

---

**Error**: "Insufficient permissions"

**Solution**: Verify IAM role has necessary permissions (see [AWS_OIDC_SETUP.md](AWS_OIDC_SETUP.md))

## Best Practices

### Always Run Diff Before Deploy

Review changes before deploying to avoid surprises:

```bash
1. Action: diff → Review changes
2. Action: deploy → Apply changes
```

### Use Environment Progression

Deploy to environments in order:

```bash
dev → staging → prod
```

### Enable Protection Rules for Production

Configure production environment with:
- Required reviewers (2+ approvals)
- Deployment branches (protected branches only)
- Wait timer (5 minutes)

### Monitor Deployments

Watch the workflow logs during deployment:
- Check for warnings or errors
- Verify resource creation/updates
- Review stack outputs

### Keep Outputs Artifacts

Download `outputs.json` artifacts for reference:
1. Go to workflow run
2. Scroll to **Artifacts**
3. Download `cdk-outputs-{environment}`

### Test in Dev First

Always test changes in dev before production:

```bash
# Make CDK changes
git checkout -b feature/new-resource

# Test in dev
Action: deploy, Environment: dev

# If successful, merge and deploy to prod
git checkout main
git merge feature/new-resource
Action: deploy, Environment: prod
```

## Additional Resources

- [AWS OIDC Setup Guide](AWS_OIDC_SETUP.md)
- [GitHub Environment Setup Guide](GITHUB_ENVIRONMENT_SETUP.md)
- [CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
