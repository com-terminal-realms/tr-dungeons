# Requirements Document

## Introduction

This feature adds a GitHub Actions workflow for deploying the TR-Dungeons build distribution CDK infrastructure, following orb-templates standards. The workflow will enable automated infrastructure deployment with proper testing, OIDC authentication, and comprehensive documentation for GitHub environment setup.

## Glossary

- **CDK**: AWS Cloud Development Kit - Infrastructure as Code framework
- **OIDC**: OpenID Connect - Authentication protocol for federated identity
- **GitHub_Actions**: GitHub's CI/CD automation platform
- **Build_Distribution_Stack**: The CDK stack that manages S3, SQS, SNS, DynamoDB, and IAM resources for game build distribution
- **Deployment_Role**: IAM role assumed by GitHub Actions via OIDC for deploying infrastructure
- **Stack_Outputs**: CDK stack export values (bucket names, queue URLs, role ARNs)
- **Orb_Templates**: Standard workflow templates from the orb-templates repository

## Requirements

### Requirement 1: GitHub Actions Deployment Workflow

**User Story:** As a developer, I want a GitHub Actions workflow to deploy CDK infrastructure, so that I can manage infrastructure changes through version control and CI/CD.

#### Acceptance Criteria

1. THE Workflow SHALL be located at `.github/workflows/deploy-infrastructure.yml`
2. WHEN triggered via workflow_dispatch, THE Workflow SHALL accept environment and action inputs
3. THE Workflow SHALL support three actions: synth, diff, and deploy
4. WHEN the synth action is selected, THE Workflow SHALL generate CloudFormation templates without deploying
5. WHEN the diff action is selected, THE Workflow SHALL show infrastructure changes without deploying
6. WHEN the deploy action is selected, THE Workflow SHALL deploy the infrastructure stack
7. THE Workflow SHALL follow the orb-templates deploy-infrastructure.yml structure and conventions

### Requirement 2: Embedded Testing Before Deployment

**User Story:** As a developer, I want automated tests to run before deployment, so that I can catch errors early and prevent broken infrastructure deployments.

#### Acceptance Criteria

1. WHEN the workflow runs, THE Workflow SHALL execute pytest tests before any CDK operations
2. WHEN the workflow runs, THE Workflow SHALL execute black formatting checks before any CDK operations
3. WHEN the workflow runs, THE Workflow SHALL execute ruff linting checks before any CDK operations
4. WHEN the workflow runs, THE Workflow SHALL execute mypy type checks before any CDK operations
5. IF any test or check fails, THEN THE Workflow SHALL stop and prevent deployment
6. THE Workflow SHALL display test results in the GitHub Actions summary

### Requirement 3: OIDC Authentication

**User Story:** As a security-conscious developer, I want to use OIDC authentication instead of long-lived credentials, so that I can deploy infrastructure securely without storing AWS access keys.

#### Acceptance Criteria

1. THE Workflow SHALL use aws-actions/configure-aws-credentials@v4 with OIDC
2. THE Workflow SHALL assume the Deployment_Role using role-to-assume parameter
3. THE Workflow SHALL NOT use long-lived AWS access keys or secret keys
4. THE Workflow SHALL require id-token: write permission for OIDC token generation
5. WHEN authentication fails, THEN THE Workflow SHALL fail with a clear error message

### Requirement 4: Stack Output Capture

**User Story:** As a developer, I want stack outputs to be captured and uploaded, so that I can access resource identifiers and URLs after deployment.

#### Acceptance Criteria

1. WHEN deployment completes successfully, THE Workflow SHALL extract stack outputs from CDK
2. THE Workflow SHALL save stack outputs to a JSON file
3. THE Workflow SHALL upload the stack outputs JSON file as a workflow artifact
4. THE Stack_Outputs SHALL include bucket names, queue URLs, table names, and role ARNs
5. THE Workflow SHALL display key stack outputs in the GitHub Actions summary

### Requirement 5: GitHub Environment Configuration Documentation

**User Story:** As a developer setting up the deployment workflow, I want comprehensive documentation on GitHub environment configuration, so that I can properly configure OIDC authentication and environment variables.

#### Acceptance Criteria

1. THE Documentation SHALL provide step-by-step instructions for creating a GitHub environment
2. THE Documentation SHALL list all required environment variables with descriptions
3. THE Documentation SHALL document the AWS_DEPLOYMENT_ROLE_ARN variable format
4. THE Documentation SHALL document the AWS_REGION variable and default value
5. THE Documentation SHALL explain how to configure environment protection rules
6. THE Documentation SHALL be located at `docs/GITHUB_ENVIRONMENT_SETUP.md`

### Requirement 6: AWS OIDC Provider Setup Documentation

**User Story:** As a developer setting up AWS infrastructure, I want documentation on creating the OIDC provider and IAM role, so that I can enable GitHub Actions to authenticate with AWS.

#### Acceptance Criteria

1. THE Documentation SHALL provide step-by-step instructions for creating the GitHub OIDC provider in AWS
2. THE Documentation SHALL document the required OIDC provider URL and thumbprints
3. THE Documentation SHALL provide step-by-step instructions for creating the Deployment_Role
4. THE Documentation SHALL document the trust policy for the Deployment_Role
5. THE Documentation SHALL document the required IAM permissions for CDK deployment
6. THE Documentation SHALL explain how to restrict the role to specific GitHub repositories
7. THE Documentation SHALL be located at `docs/AWS_OIDC_SETUP.md`

### Requirement 7: CDK Testing Configuration

**User Story:** As a developer, I want proper testing configuration for CDK code, so that I can validate infrastructure changes before deployment.

#### Acceptance Criteria

1. THE System SHALL include a pytest configuration file for CDK tests
2. THE System SHALL include a pyproject.toml file with black, ruff, and mypy configuration
3. THE System SHALL include basic CDK stack tests that validate stack creation
4. THE CDK_Tests SHALL verify that the stack synthesizes without errors
5. THE CDK_Tests SHALL verify that required resources are created (S3, SQS, SNS, DynamoDB, IAM)
6. THE Test_Files SHALL be located in `infrastructure/cdk/tests/`

### Requirement 8: Workflow Input Validation

**User Story:** As a developer, I want the workflow to validate inputs, so that I can catch configuration errors early.

#### Acceptance Criteria

1. WHEN the environment input is provided, THE Workflow SHALL validate it is not empty
2. WHEN the action input is provided, THE Workflow SHALL validate it is one of: synth, diff, deploy
3. IF invalid inputs are provided, THEN THE Workflow SHALL fail with a descriptive error message
4. THE Workflow SHALL display the selected environment and action in the job summary

### Requirement 9: Deployment Safety Controls

**User Story:** As a developer, I want safety controls in the deployment workflow, so that I can prevent accidental infrastructure changes.

#### Acceptance Criteria

1. THE Workflow SHALL only trigger via workflow_dispatch (manual trigger)
2. THE Workflow SHALL require explicit environment selection
3. THE Workflow SHALL require explicit action selection (synth/diff/deploy)
4. WHEN the diff action is used, THE Workflow SHALL display changes without applying them
5. THE Workflow SHALL support GitHub environment protection rules for production deployments

### Requirement 10: CDK Bootstrap Verification

**User Story:** As a developer, I want the workflow to verify CDK bootstrap, so that I can catch missing bootstrap stacks before deployment fails.

#### Acceptance Criteria

1. WHEN the workflow runs, THE Workflow SHALL check if the CDK bootstrap stack exists
2. IF the bootstrap stack is missing, THEN THE Workflow SHALL provide instructions for bootstrapping
3. THE Workflow SHALL display the bootstrap status in the job summary
4. THE Documentation SHALL include instructions for running CDK bootstrap
