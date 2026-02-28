"""Unit tests for BootstrapStack."""

import aws_cdk as cdk
from aws_cdk.assertions import Template, Match
import pytest

from stacks.bootstrap_stack import BootstrapStack


@pytest.fixture
def stack() -> BootstrapStack:
    """Create a test bootstrap stack instance."""
    app = cdk.App()
    app.node.set_context("environment", "dev")
    return BootstrapStack(
        app,
        "TestBootstrapStack",
        env=cdk.Environment(account="123456789012", region="us-east-1"),
    )


@pytest.fixture
def template(stack: BootstrapStack) -> Template:
    """Create a CloudFormation template from the stack."""
    return Template.from_stack(stack)


class TestStackSynthesis:
    """Tests for stack synthesis."""

    def test_stack_synthesizes_without_errors(self, stack: BootstrapStack):
        """Test that the stack synthesizes without errors."""
        # Should not raise any exceptions
        assert stack is not None


class TestIAMRole:
    """Tests for IAM role creation."""

    def test_iam_role_created(self, template: Template):
        """Test that IAM role is created."""
        template.resource_count_is("AWS::IAM::Role", 1)

    def test_iam_role_name(self, template: Template):
        """Test that IAM role has correct name."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {"RoleName": "tr-dungeons-dev-github-actions"},
        )

    def test_iam_role_trust_policy(self, template: Template):
        """Test that IAM role has correct trust policy for OIDC."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {
                "AssumeRolePolicyDocument": {
                    "Statement": Match.array_with(
                        [
                            {
                                "Action": "sts:AssumeRoleWithWebIdentity",
                                "Effect": "Allow",
                                "Principal": {
                                    "Federated": "arn:aws:iam::432045270100:oidc-provider/token.actions.githubusercontent.com"
                                },
                                "Condition": {
                                    "StringEquals": {
                                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                                    },
                                    "StringLike": {
                                        "token.actions.githubusercontent.com:sub": "repo:com-terminal-realms/tr-dungeons:*"
                                    },
                                },
                            }
                        ]
                    )
                }
            },
        )

    def test_iam_role_has_power_user_access(self, template: Template):
        """Test that IAM role has PowerUserAccess policy."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {
                "ManagedPolicyArns": Match.array_with(
                    [
                        {
                            "Fn::Join": Match.array_with(
                                [Match.array_with([Match.string_like_regexp(".*PowerUserAccess")])]
                            )
                        }
                    ]
                )
            },
        )

    def test_iam_role_has_iam_permissions(self, template: Template):
        """Test that IAM role has IAM management permissions."""
        template.has_resource_properties(
            "AWS::IAM::Role",
            {
                "Policies": Match.array_with(
                    [
                        {
                            "PolicyDocument": {
                                "Statement": Match.array_with(
                                    [
                                        {
                                            "Action": Match.array_with(
                                                [
                                                    "iam:CreateRole",
                                                    "iam:DeleteRole",
                                                    "iam:GetRole",
                                                ]
                                            ),
                                            "Effect": "Allow",
                                            "Resource": "*",
                                        }
                                    ]
                                )
                            }
                        }
                    ]
                )
            },
        )


class TestSSMParameter:
    """Tests for SSM parameter."""

    def test_ssm_parameter_created(self, template: Template):
        """Test that SSM parameter is created."""
        template.resource_count_is("AWS::SSM::Parameter", 1)

    def test_ssm_parameter_name(self, template: Template):
        """Test that SSM parameter has correct name."""
        template.has_resource_properties(
            "AWS::SSM::Parameter",
            {"Name": "/tr-dungeons/dev/deployment-role-arn"},
        )

    def test_ssm_parameter_stores_role_arn(self, template: Template):
        """Test that SSM parameter stores the role ARN."""
        template.has_resource_properties(
            "AWS::SSM::Parameter",
            {
                "Type": "String",
                "Value": {
                    "Fn::GetAtt": Match.array_with([Match.string_like_regexp(".*Role.*"), "Arn"])
                },
            },
        )
