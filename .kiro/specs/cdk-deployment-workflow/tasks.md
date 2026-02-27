# Implementation Plan: CDK Deployment Workflow

## Overview

This implementation plan breaks down the CDK deployment workflow feature into discrete coding tasks. The workflow will enable automated infrastructure deployment through GitHub Actions with comprehensive testing, OIDC authentication, and safety controls.

## Tasks

- [ ] 1. Set up CDK testing infrastructure
  - [ ] 1.1 Create pytest configuration file
    - Create `infrastructure/cdk/pytest.ini` with test discovery settings
    - Configure test markers (unit, property, integration)
    - Set up verbose output and short tracebacks
    - _Requirements: 7.1_
  
  - [ ] 1.2 Update pyproject.toml with development dependencies
    - Add pytest, pytest-cov, hypothesis to dev dependencies
    - Add black, ruff, mypy to dev dependencies
    - Configure ruff linting rules (E, F, W, I, N)
    - Configure black formatting (line-length: 100)
    - Configure mypy type checking (strict mode)
    - _Requirements: 7.2_
  
  - [ ] 1.3 Create test directory structure
    - Create `infrastructure/cdk/tests/unit/` directory
    - Create `infrastructure/cdk/tests/property/` directory
    - Create `infrastructure/cdk/tests/integration/` directory
    - Add `__init__.py` files to make directories Python packages
    - _Requirements: 7.6_

- [ ] 2. Implement CDK stack unit tests
  - [ ] 2.1 Create test file for BuildDistributionStack
    - Create `infrastructure/cdk/tests/unit/test_build_distribution_stack.py`
    - Import required testing modules (pytest, aws_cdk, Template, Match)
    - _Requirements: 7.3_
  
  - [ ] 2.2 Write unit test for S3 bucket creation
    - Test that S3 bucket is created with correct name
    - Verify versioning is enabled
    - Verify encryption is configured (S3_MANAGED)
    - Verify lifecycle rules are set
    - _Requirements: 7.5_
  
  - [ ] 2.3 Write unit test for SQS queue with DLQ
    - Test that main queue is created
    - Test that DLQ is created
    - Verify redrive policy configuration (maxReceiveCount: 3)
    - Verify retention periods
    - _Requirements: 7.5_
  
  - [ ] 2.4 Write unit test for SNS topic
    - Test that SNS topic is created
    - Verify topic name and display name
    - _Requirements: 7.5_
  
  - [ ] 2.5 Write unit test for DynamoDB table
    - Test that table is created with correct name
    - Verify partition key configuration
    - Verify billing mode (PAY_PER_REQUEST)
    - Verify point-in-time recovery is enabled
    - _Requirements: 7.5_
  
  - [ ] 2.6 Write unit test for DynamoDB GSIs
    - Test that timestamp-index GSI exists
    - Test that git_commit_sha-index GSI exists
    - Verify projection type is ALL for both
    - _Requirements: 7.5_
  
  - [ ] 2.7 Write unit test for IAM role and OIDC provider
    - Test that OIDC provider is created
    - Verify provider URL and thumbprints
    - Test that IAM role is created
    - Verify trust policy with OIDC conditions
    - Verify StringEquals condition for audience
    - Verify StringLike condition for repository
    - _Requirements: 7.5_
  
  - [ ] 2.8 Write unit test for IAM permissions
    - Test that role has S3 read/write permissions
    - Test that role has SQS send message permissions
    - Test that role has DynamoDB read/write permissions
    - _Requirements: 7.5_
  
  - [ ] 2.9 Write unit test for CloudWatch log group
    - Test that log group is created
    - Verify log group name
    - Verify retention period (ONE_MONTH)
    - _Requirements: 7.5_

- [ ]* 2.10 Write property test for stack synthesis
    - **Property 1: Stack Synthesis Success**
    - **Validates: Requirements 7.4**
    - Create `infrastructure/cdk/tests/property/test_stack_synthesis.py`
    - Use hypothesis to generate random account IDs and regions
    - Test that stack synthesizes without errors for any valid configuration
    - Verify CloudFormation template is produced
    - Run minimum 100 iterations

- [ ]* 2.11 Write property test for required resources
    - **Property 2: Required Resources Present**
    - **Validates: Requirements 7.5, 4.4**
    - Create `infrastructure/cdk/tests/property/test_required_resources.py`
    - Use hypothesis to generate random account IDs and regions
    - Test that all required resources are present in synthesized template
    - Verify resource counts (S3: 1, SQS: 2, SNS: 1, DynamoDB: 1, IAM: 1, OIDC: 1, Logs: 1)
    - Verify DynamoDB GSIs are present
    - Run minimum 100 iterations

- [ ] 3. Add stack outputs to CDK stack
  - [ ] 3.1 Add CfnOutput for S3 bucket name
    - Add CfnOutput construct for builds_bucket.bucket_name
    - Set output key: "BuildsBucketName"
    - Set description
    - _Requirements: 4.4_
  
  - [ ] 3.2 Add CfnOutput for SQS queue URL
    - Add CfnOutput construct for notification_queue.queue_url
    - Set output key: "NotificationQueueUrl"
    - Set description
    - _Requirements: 4.4_
  
  - [ ] 3.3 Add CfnOutput for SNS topic ARN
    - Add CfnOutput construct for notification_topic.topic_arn
    - Set output key: "NotificationTopicArn"
    - Set description
    - _Requirements: 4.4_
  
  - [ ] 3.4 Add CfnOutput for DynamoDB table name
    - Add CfnOutput construct for metadata_table.table_name
    - Set output key: "MetadataTableName"
    - Set description
    - _Requirements: 4.4_
  
  - [ ] 3.5 Add CfnOutput for IAM role ARN
    - Add CfnOutput construct for github_actions_role.role_arn
    - Set output key: "GitHubActionsRoleArn"
    - Set description
    - _Requirements: 4.4_

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Create GitHub Actions workflow file
  - [ ] 5.1 Create workflow file with basic structure
    - Create `.github/workflows/deploy-infrastructure.yml`
    - Add workflow name: "Deploy Infrastructure"
    - Configure workflow_dispatch trigger
    - Add environment input (string, required)
    - Add action input (choice: synth, diff, deploy, required)
    - Set permissions (id-token: write, contents: read)
    - Define environment variables (AWS_REGION, CDK_STACK_NAME)
    - _Requirements: 1.1, 1.2, 1.3, 9.1, 9.2, 9.3_
  
  - [ ] 5.2 Add checkout and Python setup steps
    - Add actions/checkout@v4 step
    - Add actions/setup-python@v5 step with Python 3.11
    - Add step to install CDK and dependencies
    - _Requirements: 1.2_
  
  - [ ] 5.3 Add input validation steps
    - Add step to validate environment input is not empty
    - Add step to validate action input is one of: synth, diff, deploy
    - Add step to display selected environment and action
    - Exit with error if validation fails
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [ ] 5.4 Add test suite steps
    - Add step to run pytest tests
    - Add step to run black formatting check
    - Add step to run ruff linting check
    - Add step to run mypy type checking
    - Configure each step to fail workflow on error
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ] 5.5 Add test results summary step
    - Add step to parse test results
    - Add step to display results in GitHub Actions summary
    - Include pass/fail counts for each tool
    - _Requirements: 2.6_
  
  - [ ] 5.6 Add OIDC authentication step
    - Add aws-actions/configure-aws-credentials@v4 step
    - Configure role-to-assume from secrets.AWS_DEPLOYMENT_ROLE_ARN
    - Configure aws-region from env.AWS_REGION
    - Set role-session-name with github.run_id
    - Add error handling for authentication failures
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 5.7 Add CDK bootstrap verification step
    - Add step to check if CDKToolkit stack exists
    - Use aws cloudformation describe-stacks command
    - Display bootstrap status in job summary
    - If missing, display bootstrap instructions and fail
    - _Requirements: 10.1, 10.2, 10.3_
  
  - [ ] 5.8 Add CDK synth operation
    - Add conditional step for synth action
    - Run cdk synth command with environment context
    - Display generated templates
    - _Requirements: 1.4_
  
  - [ ] 5.9 Add CDK diff operation
    - Add conditional step for diff action
    - Run cdk diff command with environment context
    - Display infrastructure changes
    - _Requirements: 1.5, 9.4_
  
  - [ ] 5.10 Add CDK deploy operation
    - Add conditional step for deploy action
    - Run cdk deploy command with environment context
    - Use --require-approval never flag
    - Use --outputs-file outputs.json flag
    - _Requirements: 1.6_
  
  - [ ] 5.11 Add stack output capture steps
    - Add conditional step (only after successful deploy)
    - Parse outputs.json file
    - Extract key outputs (bucket, queue, topic, table, role)
    - Upload outputs.json as workflow artifact
    - Display key outputs in job summary
    - _Requirements: 4.1, 4.2, 4.3, 4.5_
  
  - [ ] 5.12 Add deployment summary step
    - Add step to generate comprehensive job summary
    - Include environment and action
    - Include test results
    - Include stack outputs (if deploy)
    - Include next steps and documentation links
    - _Requirements: 8.4_

- [ ] 6. Create GitHub environment setup documentation
  - [ ] 6.1 Create GITHUB_ENVIRONMENT_SETUP.md
    - Create `docs/GITHUB_ENVIRONMENT_SETUP.md` file
    - Add introduction and prerequisites section
    - _Requirements: 5.6_
  
  - [ ] 6.2 Document GitHub environment creation
    - Add step-by-step instructions for creating environment
    - Include screenshots or CLI commands
    - Explain environment naming conventions
    - _Requirements: 5.1_
  
  - [ ] 6.3 Document environment variables
    - List all required environment variables
    - Document AWS_DEPLOYMENT_ROLE_ARN format and example
    - Document AWS_REGION with supported regions and default
    - Provide descriptions for each variable
    - _Requirements: 5.2, 5.3, 5.4_
  
  - [ ] 6.4 Document environment protection rules
    - Explain how to configure required reviewers
    - Explain how to configure deployment branches
    - Explain how to configure wait timers
    - Provide examples for production environment
    - _Requirements: 5.5, 9.5_
  
  - [ ] 6.5 Add testing and troubleshooting sections
    - Add section on testing the configuration
    - Add common issues and solutions
    - Add links to AWS and GitHub documentation
    - _Requirements: 5.1_

- [ ] 7. Create AWS OIDC setup documentation
  - [ ] 7.1 Create AWS_OIDC_SETUP.md
    - Create `docs/AWS_OIDC_SETUP.md` file
    - Add introduction to OIDC authentication
    - Explain benefits over long-lived credentials
    - _Requirements: 6.7_
  
  - [ ] 7.2 Document OIDC provider creation
    - Add step-by-step instructions for creating provider
    - Document provider URL: https://token.actions.githubusercontent.com
    - Document audience: sts.amazonaws.com
    - Document thumbprints with update instructions
    - Provide AWS CLI and Console instructions
    - _Requirements: 6.1, 6.2_
  
  - [ ] 7.3 Document IAM role creation
    - Add step-by-step instructions for creating role
    - Provide role name convention
    - Document trust policy template
    - Explain repository restrictions in trust policy
    - Provide AWS CLI and Console instructions
    - _Requirements: 6.3, 6.4, 6.6_
  
  - [ ] 7.4 Document IAM permissions
    - List all required permissions for CDK deployment
    - Document CloudFormation permissions
    - Document S3, SQS, SNS, DynamoDB, IAM permissions
    - Provide complete policy document example
    - Explain least privilege principle
    - _Requirements: 6.5_
  
  - [ ] 7.5 Add testing and security sections
    - Add section on testing OIDC authentication
    - Add security best practices
    - Add troubleshooting common issues
    - Add links to AWS documentation
    - _Requirements: 6.1_

- [ ] 8. Create deployment workflow usage documentation
  - [ ] 8.1 Create DEPLOYMENT_WORKFLOW.md
    - Create `docs/DEPLOYMENT_WORKFLOW.md` file
    - Add overview of the deployment workflow
    - Explain the three-action model (synth, diff, deploy)
    - _Requirements: 1.3_
  
  - [ ] 8.2 Document workflow triggering
    - Add instructions for manual trigger via GitHub UI
    - Document input parameters (environment, action)
    - Provide examples for each action
    - _Requirements: 1.2_
  
  - [ ] 8.3 Document workflow actions
    - Explain synth action and when to use it
    - Explain diff action and when to use it
    - Explain deploy action and when to use it
    - Provide use case examples
    - _Requirements: 1.4, 1.5, 1.6_
  
  - [ ] 8.4 Document workflow output
    - Explain how to read test results
    - Explain how to interpret stack outputs
    - Explain how to read deployment summary
    - Provide example outputs
    - _Requirements: 2.6, 4.5_
  
  - [ ] 8.5 Add common workflows and troubleshooting
    - Document first-time deployment workflow
    - Document updating infrastructure workflow
    - Document rolling back changes workflow
    - Add troubleshooting section
    - _Requirements: 1.1_

- [ ] 9. Add CDK bootstrap documentation
  - [ ] 9.1 Add bootstrap section to AWS_OIDC_SETUP.md
    - Add section explaining CDK bootstrap
    - Document bootstrap command: cdk bootstrap aws://ACCOUNT/REGION
    - Explain what bootstrap creates (CDKToolkit stack)
    - Explain when bootstrap is needed
    - _Requirements: 10.4_
  
  - [ ] 9.2 Add bootstrap verification to DEPLOYMENT_WORKFLOW.md
    - Add section on bootstrap verification in workflow
    - Explain what happens if bootstrap is missing
    - Document how to fix missing bootstrap
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (minimum 100 iterations)
- Unit tests validate specific examples and edge cases
- The workflow follows orb-templates standards for consistency
- OIDC authentication provides better security than long-lived credentials
- Documentation is comprehensive to support first-time setup
