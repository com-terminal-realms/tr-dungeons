"""CDK stack for game build distribution system.

This stack creates the AWS infrastructure for automated game builds:
- S3 bucket for storing build artifacts
- SQS queue for notification messages
- SNS topic for fan-out notifications
- DynamoDB table for build metadata
- IAM role for GitHub Actions OIDC
"""

from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    aws_s3 as s3,
    aws_sqs as sqs,
    aws_sns as sns,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    aws_logs as logs,
)
from constructs import Construct


class BuildDistributionStack(Stack):
    """Stack for game build distribution infrastructure."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # S3 bucket for build artifacts
        self.builds_bucket = s3.Bucket(
            self,
            "BuildsBucket",
            bucket_name="tr-dungeons-builds",
            versioned=True,
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.RETAIN,
            lifecycle_rules=[
                s3.LifecycleRule(
                    id="RetainLast5Versions",
                    enabled=True,
                    noncurrent_version_expiration=Duration.days(1),
                    noncurrent_versions_to_retain=5,
                )
            ],
        )

        # Dead letter queue for failed notifications
        dlq = sqs.Queue(
            self,
            "NotificationDLQ",
            queue_name="tr-dungeons-build-notifications-dlq",
            retention_period=Duration.days(14),
        )

        # SQS queue for build notifications
        self.notification_queue = sqs.Queue(
            self,
            "NotificationQueue",
            queue_name="tr-dungeons-build-notifications",
            visibility_timeout=Duration.seconds(30),
            retention_period=Duration.days(14),
            dead_letter_queue=sqs.DeadLetterQueue(
                max_receive_count=3,
                queue=dlq,
            ),
        )

        # SNS topic for fan-out notifications
        self.notification_topic = sns.Topic(
            self,
            "NotificationTopic",
            topic_name="tr-dungeons-build-releases",
            display_name="TR-Dungeons Build Releases",
        )

        # DynamoDB table for build metadata
        self.metadata_table = dynamodb.Table(
            self,
            "MetadataTable",
            table_name="tr-dungeons-build-metadata",
            partition_key=dynamodb.Attribute(
                name="version",
                type=dynamodb.AttributeType.STRING,
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.RETAIN,
            point_in_time_recovery=True,
        )

        # Add GSI for timestamp queries
        self.metadata_table.add_global_secondary_index(
            index_name="timestamp-index",
            partition_key=dynamodb.Attribute(
                name="timestamp",
                type=dynamodb.AttributeType.STRING,
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # Add GSI for git commit queries
        self.metadata_table.add_global_secondary_index(
            index_name="git_commit_sha-index",
            partition_key=dynamodb.Attribute(
                name="git_commit_sha",
                type=dynamodb.AttributeType.STRING,
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # IAM role for GitHub Actions with OIDC
        github_provider = iam.OpenIdConnectProvider.from_open_id_connect_provider_arn(
            self,
            "GitHubProvider",
            open_id_connect_provider_arn=f"arn:aws:iam::{self.account}:oidc-provider/token.actions.githubusercontent.com",
        )

        self.github_actions_role = iam.Role(
            self,
            "GitHubActionsRole",
            role_name="tr-dungeons-github-actions-role",
            assumed_by=iam.WebIdentityPrincipal(
                github_provider.open_id_connect_provider_arn,
                conditions={
                    "StringEquals": {
                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    },
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*",
                    },
                },
            ),
            description="Role for GitHub Actions to deploy builds",
            max_session_duration=Duration.hours(1),
        )

        # Grant permissions to GitHub Actions role
        self.builds_bucket.grant_read_write(self.github_actions_role)
        self.notification_queue.grant_send_messages(self.github_actions_role)
        self.metadata_table.grant_read_write_data(self.github_actions_role)

        # CloudWatch log group for monitoring
        logs.LogGroup(
            self,
            "BuildDistributionLogs",
            log_group_name="/aws/tr-dungeons/build-distribution",
            retention=logs.RetentionDays.ONE_MONTH,
            removal_policy=RemovalPolicy.DESTROY,
        )
