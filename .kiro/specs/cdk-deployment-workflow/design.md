# Design Document: CDK Deployment Workflow

## Overview

This design implements a GitHub Actions workflow for deploying the TR-Dungeons build distribution CDK infrastructure. The workflow follows orb-templates standards and provides automated infrastructure deployment with comprehensive testing, OIDC authentication, and safety controls.

The workflow enables developers to manage infrastructure changes through version control and CI/CD, with three deployment modes: synth (generate templates), diff (preview changes), and deploy (apply changes). All operations include embedded testing to catch errors before deployment.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                      │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Validate   │───▶│     Test     │───▶│     CDK      │      │
│  │    Inputs    │    │    Suite     │    │   Operation  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                    │                    │              │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              OIDC Authentication                      │      │
│  │         (aws-actions/configure-aws-credentials)       │      │
│  └──────────────────────────────────────────────────────┘      │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │    AWS Account       │
                    │                      │
                    │  ┌────────────────┐ │
                    │  │ CDK Bootstrap  │ │
                    │  │     Stack      │ │
                    │  └────────────────┘ │
                    │          │          │
                    │          ▼          │
                    │  ┌────────────────┐ │
                    │  │ Build Distrib. │ │
                    │  │     Stack      │ │
                    │  │                │ │
                    │  │ • S3 Bucket    │ │
                    │  │ • SQS Queue    │ │
                    │  │ • SNS Topic    │ │
                    │  │ • DynamoDB     │ │
                    │  │ • IAM Roles    │ │
                    │  └────────────────┘ │
                    └──────────────────────┘
```

### Workflow Execution Flow

```
Manual Trigger (workflow_dispatch)
         │
         ▼
┌─────────────────────┐
│  Input Validation   │
│  • environment      │
│  • action           │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   Setup Python      │
│   Install CDK       │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   Test Suite        │
│   • pytest          │
│   • black           │
│   • ruff            │
│   • mypy            │
└─────────────────────┘
         │
         ├─── Fail ───▶ Stop
         │
         ▼ Pass
┌─────────────────────┐
│ OIDC Authentication │
│ Assume Deploy Role  │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│ Bootstrap Check     │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│   CDK Operation     │
│   • synth           │
│   • diff            │
│   • deploy          │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│  Capture Outputs    │
│  Upload Artifacts   │
│  Generate Summary   │
└─────────────────────┘
```

## Components and Interfaces

### 1. Workflow File

**Location:** `.github/workflows/deploy-infrastructure.yml`

**Inputs:**
- `environment` (string, required): Target environment (e.g., "dev", "staging", "production")
- `action` (choice, required): One of "synth", "diff", "deploy"

**Permissions:**
- `id-token: write` - Required for OIDC token generation
- `contents: read` - Required for repository checkout

**Environment Variables:**
- `AWS_REGION`: AWS region for deployment (default: "us-east-1")
- `CDK_STACK_NAME`: Name of the CDK stack to deploy

**Secrets (via GitHub Environment):**
- `AWS_DEPLOYMENT_ROLE_ARN`: ARN of the IAM role to assume

### 2. Test Suite Components

#### pytest Configuration

**Location:** `infrastructure/cdk/pytest.ini`

**Purpose:** Configure pytest for CDK stack tests

**Configuration:**
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
```

#### pyproject.toml Configuration

**Location:** `infrastructure/cdk/pyproject.toml` (already exists, will be updated)

**Tool Configurations:**
- **black**: Code formatting (line-length: 100, target: py311)
- **ruff**: Linting (select: E, F, W, I, N)
- **mypy**: Type checking (strict mode, disallow untyped defs)

#### CDK Stack Tests

**Location:** `infrastructure/cdk/tests/unit/test_build_distribution_stack.py`

**Test Cases:**
1. Stack synthesizes without errors
2. S3 bucket is created with correct configuration
3. SQS queue is created with DLQ
4. SNS topic is created
5. DynamoDB table is created with GSIs
6. IAM role is created with correct trust policy
7. Permissions are granted correctly

### 3. CDK Operations

#### Synth Operation

**Command:** `cdk synth --app "python3 app.py" --context environment={env}`

**Purpose:** Generate CloudFormation templates without deploying

**Output:** CloudFormation template JSON files

#### Diff Operation

**Command:** `cdk diff --app "python3 app.py" --context environment={env}`

**Purpose:** Show infrastructure changes without applying them

**Output:** Diff output showing additions, modifications, deletions

#### Deploy Operation

**Command:** `cdk deploy --app "python3 app.py" --context environment={env} --require-approval never --outputs-file outputs.json`

**Purpose:** Deploy infrastructure changes to AWS

**Output:** 
- Deployment progress logs
- Stack outputs in JSON format

### 4. OIDC Authentication

**Action:** `aws-actions/configure-aws-credentials@v4`

**Configuration:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_DEPLOYMENT_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
    role-session-name: GitHubActions-${{ github.run_id }}
```

**Trust Policy Requirements:**
- OIDC provider: `token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`
- Subject: `repo:{org}/{repo}:*` (can be restricted to specific branches/environments)

### 5. Stack Output Capture

**Process:**
1. CDK deploy writes outputs to `outputs.json`
2. Parse JSON to extract key outputs
3. Upload as workflow artifact
4. Display in job summary

**Output Format:**
```json
{
  "TRDungeonsBuildDistribution": {
    "BuildsBucketName": "tr-dungeons-builds",
    "NotificationQueueUrl": "https://sqs.us-east-1.amazonaws.com/...",
    "NotificationTopicArn": "arn:aws:sns:us-east-1:...",
    "MetadataTableName": "tr-dungeons-build-metadata",
    "GitHubActionsRoleArn": "arn:aws:iam::...:role/tr-dungeons-github-actions-role"
  }
}
```

### 6. Bootstrap Verification

**Implementation:**
```bash
# Check if CDK bootstrap stack exists
aws cloudformation describe-stacks \
  --stack-name CDKToolkit \
  --region $AWS_REGION \
  || echo "⚠️  CDK bootstrap stack not found. Run: cdk bootstrap aws://ACCOUNT/REGION"
```

**Behavior:**
- If bootstrap stack exists: Continue with deployment
- If bootstrap stack missing: Display instructions and fail

## Data Models

### Workflow Inputs

```yaml
inputs:
  environment:
    description: 'Target environment (dev, staging, production)'
    required: true
    type: string
  
  action:
    description: 'CDK action to perform'
    required: true
    type: choice
    options:
      - synth
      - diff
      - deploy
```

### Stack Outputs Schema

```typescript
interface StackOutputs {
  [stackName: string]: {
    [outputKey: string]: string;
  };
}

interface BuildDistributionOutputs {
  BuildsBucketName: string;
  NotificationQueueUrl: string;
  NotificationTopicArn: string;
  MetadataTableName: string;
  GitHubActionsRoleArn: string;
}
```

### Test Results Schema

```typescript
interface TestResults {
  pytest: {
    passed: number;
    failed: number;
    skipped: number;
    total: number;
  };
  black: {
    status: 'passed' | 'failed';
    filesChecked: number;
  };
  ruff: {
    status: 'passed' | 'failed';
    violations: number;
  };
  mypy: {
    status: 'passed' | 'failed';
    errors: number;
  };
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Stack Synthesis Success

*For any* valid CDK app configuration with the BuildDistributionStack, synthesizing the stack should complete without errors and produce valid CloudFormation templates.

**Validates: Requirements 7.4**

### Property 2: Required Resources Present

*For any* synthesized BuildDistributionStack, the CloudFormation template should contain all required resource types: S3 bucket, SQS queue (with DLQ), SNS topic, DynamoDB table (with GSIs), and IAM role with OIDC provider.

**Validates: Requirements 7.5, 4.4**

## Error Handling

### Workflow-Level Error Handling

**Test Failures:**
- Any test failure (pytest, black, ruff, mypy) stops the workflow immediately
- Error output is displayed in the job summary
- Exit code is non-zero to indicate failure

**Authentication Failures:**
- OIDC authentication failures display clear error messages
- Common issues are documented (missing role, incorrect trust policy, expired token)
- Workflow fails with actionable error message

**Bootstrap Missing:**
- Bootstrap check detects missing CDKToolkit stack
- Displays instructions: `cdk bootstrap aws://ACCOUNT_ID/REGION`
- Workflow fails with clear message about bootstrap requirement

**CDK Operation Failures:**
- Synth failures display CloudFormation synthesis errors
- Diff failures display comparison errors
- Deploy failures display CloudFormation deployment errors
- All errors are captured in job summary

### Input Validation

**Environment Input:**
```yaml
- name: Validate environment input
  run: |
    if [ -z "${{ inputs.environment }}" ]; then
      echo "❌ Error: environment input is required"
      exit 1
    fi
    echo "✅ Environment: ${{ inputs.environment }}"
```

**Action Input:**
```yaml
- name: Validate action input
  run: |
    ACTION="${{ inputs.action }}"
    if [[ ! "$ACTION" =~ ^(synth|diff|deploy)$ ]]; then
      echo "❌ Error: action must be one of: synth, diff, deploy"
      exit 1
    fi
    echo "✅ Action: $ACTION"
```

### CDK-Level Error Handling

**Stack Synthesis Errors:**
- Invalid resource configurations are caught during synth
- Type errors are caught by mypy before synthesis
- Construct errors display stack trace

**Deployment Errors:**
- CloudFormation rollback on deployment failure
- Stack remains in previous stable state
- Error details available in CloudFormation console

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests:**
- Specific examples of stack configurations
- Edge cases (empty contexts, missing parameters)
- Error conditions (invalid resource names, missing permissions)
- Integration points (OIDC provider creation, role trust policies)

**Property Tests:**
- Universal properties that hold for all valid stack configurations
- Comprehensive input coverage through randomization
- Minimum 100 iterations per property test

### Unit Testing

**Test Framework:** pytest

**Test Location:** `infrastructure/cdk/tests/unit/`

**Test Files:**
- `test_build_distribution_stack.py` - Stack creation and resource tests
- `test_stack_outputs.py` - Output validation tests
- `test_iam_policies.py` - Permission and trust policy tests

**Example Unit Tests:**

```python
def test_stack_creates_s3_bucket():
    """Test that the stack creates an S3 bucket with correct configuration."""
    app = cdk.App()
    stack = BuildDistributionStack(app, "TestStack")
    template = Template.from_stack(stack)
    
    template.has_resource_properties("AWS::S3::Bucket", {
        "BucketName": "tr-dungeons-builds",
        "VersioningConfiguration": {"Status": "Enabled"},
        "BucketEncryption": {
            "ServerSideEncryptionConfiguration": [{
                "ServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }
    })

def test_stack_creates_sqs_queue_with_dlq():
    """Test that the stack creates an SQS queue with dead letter queue."""
    app = cdk.App()
    stack = BuildDistributionStack(app, "TestStack")
    template = Template.from_stack(stack)
    
    # Check main queue exists
    template.resource_count_is("AWS::SQS::Queue", 2)  # Main + DLQ
    
    # Check DLQ configuration
    template.has_resource_properties("AWS::SQS::Queue", {
        "QueueName": "tr-dungeons-build-notifications",
        "RedrivePolicy": Match.object_like({
            "maxReceiveCount": 3
        })
    })

def test_iam_role_trust_policy():
    """Test that the IAM role has correct OIDC trust policy."""
    app = cdk.App()
    stack = BuildDistributionStack(app, "TestStack")
    template = Template.from_stack(stack)
    
    template.has_resource_properties("AWS::IAM::Role", {
        "AssumeRolePolicyDocument": {
            "Statement": Match.array_with([
                Match.object_like({
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                        },
                        "StringLike": {
                            "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*"
                        }
                    }
                })
            ])
        }
    })
```

### Property-Based Testing

**Test Framework:** pytest + hypothesis

**Test Location:** `infrastructure/cdk/tests/property/`

**Configuration:**
- Minimum 100 iterations per property test
- Each test tagged with feature and property reference

**Property Test 1: Stack Synthesis Success**

```python
from hypothesis import given, strategies as st
import pytest
import aws_cdk as cdk
from stacks.build_distribution_stack import BuildDistributionStack

# Feature: cdk-deployment-workflow, Property 1: Stack Synthesis Success
@given(
    account=st.text(min_size=12, max_size=12, alphabet=st.characters(whitelist_categories=('Nd',))),
    region=st.sampled_from(['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1'])
)
@pytest.mark.property
def test_stack_synthesizes_successfully(account: str, region: str):
    """
    Property: For any valid CDK app configuration, the stack should synthesize without errors.
    
    Validates: Requirements 7.4
    """
    app = cdk.App()
    stack = BuildDistributionStack(
        app,
        "TestStack",
        env=cdk.Environment(account=account, region=region)
    )
    
    # Should not raise any exceptions
    template = app.synth()
    
    # Verify template was created
    assert template is not None
    assert len(template.stacks) > 0
```

**Property Test 2: Required Resources Present**

```python
from hypothesis import given, strategies as st
import pytest
import aws_cdk as cdk
from aws_cdk.assertions import Template
from stacks.build_distribution_stack import BuildDistributionStack

# Feature: cdk-deployment-workflow, Property 2: Required Resources Present
@given(
    account=st.text(min_size=12, max_size=12, alphabet=st.characters(whitelist_categories=('Nd',))),
    region=st.sampled_from(['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1'])
)
@pytest.mark.property
def test_required_resources_present(account: str, region: str):
    """
    Property: For any synthesized stack, all required resources should be present.
    
    Validates: Requirements 7.5, 4.4
    """
    app = cdk.App()
    stack = BuildDistributionStack(
        app,
        "TestStack",
        env=cdk.Environment(account=account, region=region)
    )
    template = Template.from_stack(stack)
    
    # Verify S3 bucket
    template.resource_count_is("AWS::S3::Bucket", 1)
    
    # Verify SQS queues (main + DLQ)
    template.resource_count_is("AWS::SQS::Queue", 2)
    
    # Verify SNS topic
    template.resource_count_is("AWS::SNS::Topic", 1)
    
    # Verify DynamoDB table
    template.resource_count_is("AWS::DynamoDB::Table", 1)
    
    # Verify DynamoDB GSIs
    template.has_resource_properties("AWS::DynamoDB::Table", {
        "GlobalSecondaryIndexes": Match.array_with([
            Match.object_like({"IndexName": "timestamp-index"}),
            Match.object_like({"IndexName": "git_commit_sha-index"})
        ])
    })
    
    # Verify IAM role
    template.resource_count_is("AWS::IAM::Role", 1)
    
    # Verify OIDC provider
    template.resource_count_is("Custom::AWSCDKOpenIdConnectProvider", 1)
    
    # Verify CloudWatch log group
    template.resource_count_is("AWS::Logs::LogGroup", 1)
```

### Integration Testing

**Workflow Integration Tests:**
- Test workflow file syntax with `actionlint`
- Validate YAML structure
- Check required inputs and outputs are defined

**CDK Integration Tests:**
- Deploy to test AWS account
- Verify resources are created correctly
- Test OIDC authentication flow
- Verify stack outputs are captured

### Test Execution

**Local Testing:**
```bash
# Run all tests
cd infrastructure/cdk
pytest

# Run unit tests only
pytest tests/unit/

# Run property tests only
pytest tests/property/

# Run with coverage
pytest --cov=stacks --cov-report=html
```

**CI Testing (in workflow):**
```yaml
- name: Run tests
  run: |
    cd infrastructure/cdk
    pytest -v --tb=short
    
- name: Check formatting
  run: |
    cd infrastructure/cdk
    black --check .
    
- name: Run linting
  run: |
    cd infrastructure/cdk
    ruff check .
    
- name: Run type checking
  run: |
    cd infrastructure/cdk
    mypy stacks/
```

## Documentation Structure

### GitHub Environment Setup Documentation

**Location:** `docs/GITHUB_ENVIRONMENT_SETUP.md`

**Contents:**
1. Introduction and prerequisites
2. Creating a GitHub environment
3. Configuring environment variables
   - `AWS_DEPLOYMENT_ROLE_ARN` - Full ARN format and example
   - `AWS_REGION` - Supported regions and default
4. Setting up environment protection rules
   - Required reviewers for production
   - Deployment branches
   - Wait timer
5. Testing the configuration
6. Troubleshooting common issues

### AWS OIDC Setup Documentation

**Location:** `docs/AWS_OIDC_SETUP.md`

**Contents:**
1. Introduction to OIDC authentication
2. Creating the GitHub OIDC provider
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
   - Thumbprints (with update instructions)
3. Creating the deployment IAM role
   - Role name convention
   - Trust policy template
   - Repository restrictions
4. Configuring IAM permissions
   - Required permissions for CDK deployment
   - CloudFormation permissions
   - S3, SQS, SNS, DynamoDB, IAM permissions
5. Testing OIDC authentication
6. Security best practices
7. Troubleshooting

### Workflow Usage Documentation

**Location:** `docs/DEPLOYMENT_WORKFLOW.md`

**Contents:**
1. Overview of the deployment workflow
2. Triggering the workflow
   - Manual trigger via GitHub UI
   - Input parameters
3. Workflow actions
   - Synth: Generate templates
   - Diff: Preview changes
   - Deploy: Apply changes
4. Understanding workflow output
   - Test results
   - Stack outputs
   - Deployment summary
5. Common workflows
   - First-time deployment
   - Updating infrastructure
   - Rolling back changes
6. Troubleshooting

## Configuration Files

### pytest.ini

**Location:** `infrastructure/cdk/pytest.ini`

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
markers =
    unit: Unit tests
    property: Property-based tests
    integration: Integration tests
```

### pyproject.toml Updates

**Location:** `infrastructure/cdk/pyproject.toml`

**Additions to existing file:**

```toml
[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "hypothesis>=6.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]

[tool.ruff]
select = ["E", "F", "W", "I", "N"]
line-length = 100
target-version = "py311"

[tool.ruff.per-file-ignores]
"__init__.py" = ["F401"]
```

### GitHub Workflow File Structure

**Location:** `.github/workflows/deploy-infrastructure.yml`

**Structure:**
```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: string
      action:
        description: 'CDK action to perform'
        required: true
        type: choice
        options:
          - synth
          - diff
          - deploy

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  CDK_STACK_NAME: TRDungeonsBuildDistribution

jobs:
  deploy:
    name: Deploy CDK Infrastructure
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - name: Checkout code
      - name: Setup Python
      - name: Install dependencies
      - name: Validate inputs
      - name: Run pytest
      - name: Run black
      - name: Run ruff
      - name: Run mypy
      - name: Configure AWS credentials (OIDC)
      - name: Verify CDK bootstrap
      - name: CDK synth/diff/deploy
      - name: Capture stack outputs
      - name: Upload artifacts
      - name: Generate summary
```

## Implementation Notes

### Workflow Design Decisions

1. **Manual trigger only:** Prevents accidental infrastructure changes
2. **Embedded testing:** Catches errors before AWS operations
3. **OIDC authentication:** More secure than long-lived credentials
4. **Three-action model:** Provides flexibility (preview vs deploy)
5. **Stack output capture:** Makes deployment results accessible

### CDK Stack Considerations

1. **Existing stack:** The BuildDistributionStack already exists and is deployed
2. **No changes to stack:** This feature only adds deployment automation
3. **Stack outputs:** Need to add CfnOutput constructs for key resources
4. **Bootstrap dependency:** Workflow checks for CDKToolkit stack

### Testing Approach

1. **Limited property tests:** Most requirements are about workflow configuration, not testable logic
2. **Focus on CDK stack:** Property tests validate stack synthesis and resources
3. **Integration testing:** Workflow behavior tested through actual execution
4. **Documentation testing:** Manual review of documentation completeness

### Security Considerations

1. **OIDC over access keys:** Temporary credentials with automatic rotation
2. **Repository restrictions:** Trust policy limits which repos can assume role
3. **Environment protection:** GitHub environments add approval gates
4. **Least privilege:** IAM role has only required permissions
5. **Audit trail:** CloudWatch logs and GitHub Actions logs

## Dependencies

### Python Dependencies

```
aws-cdk-lib>=2.100.0
constructs>=10.0.0
pytest>=7.0.0
pytest-cov>=4.0.0
hypothesis>=6.0.0
black>=23.0.0
ruff>=0.1.0
mypy>=1.0.0
```

### GitHub Actions

```
actions/checkout@v4
actions/setup-python@v5
aws-actions/configure-aws-credentials@v4
actions/upload-artifact@v4
```

### AWS Services

- AWS CDK CLI
- CloudFormation
- IAM (OIDC provider, roles)
- S3, SQS, SNS, DynamoDB (deployed resources)

## Deployment Sequence

1. **Prerequisites:**
   - AWS account with CDK bootstrapped
   - GitHub OIDC provider created in AWS
   - IAM deployment role created
   - GitHub environment configured

2. **First Deployment:**
   - Run workflow with action: synth (verify templates)
   - Run workflow with action: diff (preview changes)
   - Run workflow with action: deploy (apply changes)

3. **Subsequent Deployments:**
   - Make infrastructure changes in code
   - Run diff to preview
   - Run deploy to apply

4. **Rollback:**
   - Revert code changes
   - Run diff to verify rollback
   - Run deploy to apply rollback
