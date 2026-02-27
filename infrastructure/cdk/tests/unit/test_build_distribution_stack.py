"""Unit tests for BuildDistributionStack."""

import aws_cdk as cdk
from aws_cdk.assertions import Template, Match
import pytest

from stacks.build_distribution_stack import BuildDistributionStack


@pytest.fixture
def stack() -> BuildDistributionStack:
    """Create a test stack instance."""
    app = cdk.App()
    return BuildDistributionStack(
        app,
        "TestStack",
        env=cdk.Environment(account="123456789012", region="us-east-1"),
    )


@pytest.fixture
def template(stack: BuildDistributionStack) -> Template:
    """Create a CloudFormation template from the stack."""
    return Template.from_stack(stack)


class TestStackSynthesis:
    """Tests for stack synthesis."""

    def test_stack_synthesizes_without_errors(self, stack: BuildDistributionStack):
        """Test that the stack synthesizes without errors."""
        # Should not raise any exceptions
        template = Template.from_stack(stack)
        assert template is not None


class TestS3Bucket:
    """Tests for S3 bucket configuration."""

    def test_s3_bucket_created(self, template: Template):
        """Test that S3 bucket is created."""
        template.resource_count_is("AWS::S3::Bucket", 1)

    def test_s3_bucket_name(self, template: Template):
        """Test that S3 bucket has correct name."""
        template.has_resource_properties(
            "AWS::S3::Bucket",
            {"BucketName": "tr-dungeons-builds"},
        )

    def test_s3_bucket_versioning_enabled(self, template: Template):
        """Test that S3 bucket versioning is enabled."""
        template.has_resource_properties(
            "AWS::S3::Bucket",
            {"VersioningConfiguration": {"Status": "Enabled"}},
        )

    def test_s3_bucket_encryption(self, template: Template):
        """Test that S3 bucket encryption is configured."""
        template.has_resource_properties(
            "AWS::S3::Bucket",
            {
                "BucketEncryption": {
                    "ServerSideEncryptionConfiguration": [
                        {
                            "ServerSideEncryptionByDefault": {
                                "SSEAlgorithm": "AES256"
                            }
                        }
                    ]
                }
            },
        )

    def test_s3_bucket_public_access_blocked(self, template: Template):
        """Test that S3 bucket blocks public access."""
        template.has_resource_properties(
            "AWS::S3::Bucket",
            {
                "PublicAccessBlockConfiguration": {
                    "BlockPublicAcls": True,
                    "BlockPublicPolicy": True,
                    "IgnorePublicAcls": True,
                    "RestrictPublicBuckets": True,
                }
            },
        )

    def test_s3_bucket_lifecycle_rules(self, template: Template):
        """Test that S3 bucket has lifecycle rules configured."""
        template.has_resource_properties(
            "AWS::S3::Bucket",
            {
                "LifecycleConfiguration": {
                    "Rules": Match.array_with(
                        [
                            Match.object_like(
                                {
                                    "Id": "RetainLast5Versions",
                                    "Status": "Enabled",
                                    "NoncurrentVersionExpiration": Match.object_like(
                                        {"NoncurrentDays": 1}
                                    ),
                                }
                            )
                        ]
                    )
                }
            },
        )


class TestSQSQueue:
    """Tests for SQS queue configuration."""

    def test_sqs_queues_created(self, template: Template):
        """Test that SQS queues are created (main + DLQ)."""
        template.resource_count_is("AWS::SQS::Queue", 2)

    def test_main_queue_name(self, template: Template):
        """Test that main queue has correct name."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {"QueueName": "tr-dungeons-build-notifications"},
        )

    def test_dlq_name(self, template: Template):
        """Test that DLQ has correct name."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {"QueueName": "tr-dungeons-build-notifications-dlq"},
        )

    def test_main_queue_visibility_timeout(self, template: Template):
        """Test that main queue has correct visibility timeout."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {
                "QueueName": "tr-dungeons-build-notifications",
                "VisibilityTimeout": 30,
            },
        )

    def test_main_queue_retention_period(self, template: Template):
        """Test that main queue has correct retention period."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {
                "QueueName": "tr-dungeons-build-notifications",
                "MessageRetentionPeriod": 1209600,  # 14 days
            },
        )

    def test_dlq_retention_period(self, template: Template):
        """Test that DLQ has correct retention period."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {
                "QueueName": "tr-dungeons-build-notifications-dlq",
                "MessageRetentionPeriod": 1209600,  # 14 days
            },
        )

    def test_main_queue_redrive_policy(self, template: Template):
        """Test that main queue has redrive policy configured."""
        template.has_resource_properties(
            "AWS::SQS::Queue",
            {
                "QueueName": "tr-dungeons-build-notifications",
                "RedrivePolicy": Match.object_like({"maxReceiveCount": 3}),
            },
        )


class TestSNSTopic:
    """Tests for SNS topic configuration."""

    def test_sns_topic_created(self, template: Template):
        """Test that SNS topic is created."""
        template.resource_count_is("AWS::SNS::Topic", 1)

    def test_sns_topic_name(self, template: Template):
        """Test that SNS topic has correct name."""
        template.has_resource_properties(
            "AWS::SNS::Topic",
            {"TopicName": "tr-dungeons-build-releases"},
        )

    def test_sns_topic_display_name(self, template: Template):
        """Test that SNS topic has correct display name."""
        template.has_resource_properties(
            "AWS::SNS::Topic",
            {"DisplayName": "TR-Dungeons Build Releases"},
        )


class TestDynamoDBTable:
    """Tests for DynamoDB table configuration."""

    def test_dynamodb_table_created(self, template: Template):
        """Test that DynamoDB table is created."""
        template.resource_count_is("AWS::DynamoDB::Table", 1)

    def test_dynamodb_table_name(self, template: Template):
        """Test that DynamoDB table has correct name."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {"TableName": "tr-dungeons-build-metadata"},
        )

    def test_dynamodb_partition_key(self, template: Template):
        """Test that DynamoDB table has correct partition key."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {
                "KeySchema": [
                    {"AttributeName": "version", "KeyType": "HASH"}
                ],
                "AttributeDefinitions": Match.array_with(
                    [{"AttributeName": "version", "AttributeType": "S"}]
                ),
            },
        )

    def test_dynamodb_billing_mode(self, template: Template):
        """Test that DynamoDB table uses on-demand billing."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {"BillingMode": "PAY_PER_REQUEST"},
        )

    def test_dynamodb_point_in_time_recovery(self, template: Template):
        """Test that DynamoDB table has point-in-time recovery enabled."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {"PointInTimeRecoverySpecification": {"PointInTimeRecoveryEnabled": True}},
        )


class TestDynamoDBGSIs:
    """Tests for DynamoDB Global Secondary Indexes."""

    def test_timestamp_index_exists(self, template: Template):
        """Test that timestamp-index GSI exists."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {
                "GlobalSecondaryIndexes": Match.array_with(
                    [
                        Match.object_like(
                            {
                                "IndexName": "timestamp-index",
                                "KeySchema": [
                                    {"AttributeName": "timestamp", "KeyType": "HASH"}
                                ],
                                "Projection": {"ProjectionType": "ALL"},
                            }
                        )
                    ]
                )
            },
        )

    def test_git_commit_sha_index_exists(self, template: Template):
        """Test that git_commit_sha-index GSI exists."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {
                "GlobalSecondaryIndexes": Match.array_with(
                    [
                        Match.object_like(
                            {
                                "IndexName": "git_commit_sha-index",
                                "KeySchema": [
                                    {"AttributeName": "git_commit_sha", "KeyType": "HASH"}
                                ],
                                "Projection": {"ProjectionType": "ALL"},
                            }
                        )
                    ]
                )
            },
        )

    def test_gsi_attribute_definitions(self, template: Template):
        """Test that GSI attributes are defined."""
        template.has_resource_properties(
            "AWS::DynamoDB::Table",
            {
                "AttributeDefinitions": Match.array_with(
                    [
                        {"AttributeName": "timestamp", "AttributeType": "S"},
                        {"AttributeName": "git_commit_sha", "AttributeType": "S"},
                    ]
                )
            },
        )


class TestIAMRole:
    """Tests for IAM role configuration."""

    def test_iam_role_created(self, template: Template):
        """Test that IAM role is created."""
        # We expect exactly 1 IAM role (the GitHub Actions role)
        # The OIDC provider is referenced, not created
        template.resource_count_is("AWS::IAM::Role", 1)

    def test_iam_role_name(self, template: Template):
        """Test that IAM role has correct name."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {"RoleName": "tr-dungeons-github-actions-role"},
        )

    def test_iam_role_trust_policy_action(self, template: Template):
        """Test that IAM role trust policy has correct action."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {
                "AssumeRolePolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            Match.object_like(
                                {"Action": "sts:AssumeRoleWithWebIdentity"}
                            )
                        ]
                    )
                }
            },
        )

    def test_iam_role_trust_policy_oidc_conditions(self, template: Template):
        """Test that IAM role trust policy has OIDC conditions."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {
                "AssumeRolePolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            Match.object_like(
                                {
                                    "Condition": {
                                        "StringEquals": {
                                            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                                        },
                                        "StringLike": {
                                            "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*"
                                        },
                                    }
                                }
                            )
                        ]
                    )
                }
            },
        )

    def test_iam_role_max_session_duration(self, template: Template):
        """Test that IAM role has correct max session duration."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {"MaxSessionDuration": 3600},  # 1 hour
        )


class TestIAMPermissions:
    """Tests for IAM role permissions."""

    def test_s3_permissions_granted(self, template: Template):
        """Test that IAM role has S3 permissions."""
        template.has_resource_properties(
            "AWS::IAM::Policy",
            {
                "PolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            Match.object_like(
                                {
                                    "Action": Match.array_with(
                                        [
                                            "s3:GetObject*",
                                            "s3:GetBucket*",
                                            "s3:List*",
                                        ]
                                    ),
                                    "Effect": "Allow",
                                    "Resource": Match.any_value(),  # Accept CloudFormation intrinsic functions
                                }
                            )
                        ]
                    )
                }
            },
        )

    def test_sqs_permissions_granted(self, template: Template):
        """Test that IAM role has SQS permissions."""
        template.has_resource_properties(
            "AWS::IAM::Policy",
            {
                "PolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            Match.object_like(
                                {
                                    "Action": Match.array_with(
                                        [
                                            "sqs:SendMessage",
                                            "sqs:GetQueueAttributes",
                                            "sqs:GetQueueUrl",
                                        ]
                                    ),
                                    "Effect": "Allow",
                                    "Resource": Match.any_value(),  # Accept CloudFormation intrinsic functions
                                }
                            )
                        ]
                    )
                }
            },
        )

    def test_dynamodb_permissions_granted(self, template: Template):
        """Test that IAM role has DynamoDB permissions."""
        # The grant_read_write_data() method creates multiple statements
        # We just verify that DynamoDB actions are present in the policy
        template.has_resource_properties(
            "AWS::IAM::Policy",
            {
                "PolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            Match.object_like(
                                {
                                    "Action": Match.array_with(
                                        [
                                            Match.string_like_regexp("dynamodb:.*"),
                                        ]
                                    ),
                                    "Effect": "Allow",
                                    "Resource": Match.any_value(),
                                }
                            )
                        ]
                    )
                }
            },
        )


class TestCloudWatchLogs:
    """Tests for CloudWatch log group configuration."""

    def test_log_group_created(self, template: Template):
        """Test that CloudWatch log group is created."""
        template.resource_count_is("AWS::Logs::LogGroup", 1)

    def test_log_group_name(self, template: Template):
        """Test that log group has correct name."""
        template.has_resource_properties(
            "AWS::Logs::LogGroup",
            {"LogGroupName": "/aws/tr-dungeons/build-distribution"},
        )

    def test_log_group_retention(self, template: Template):
        """Test that log group has correct retention period."""
        template.has_resource_properties(
            "AWS::Logs::LogGroup",
            {"RetentionInDays": 30},
        )
