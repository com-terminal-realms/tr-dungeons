"""Bootstrap stack for TR-Dungeons infrastructure.

Creates the project-specific GitHub Actions deployment role.
This stack is deployed using the shared orb-infrastructure role.
"""

import aws_cdk as cdk
from aws_cdk import aws_iam as iam
from aws_cdk import aws_ssm as ssm
from constructs import Construct


class BootstrapStack(cdk.Stack):
    """Bootstrap stack that creates project-specific deployment infrastructure."""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        **kwargs,
    ) -> None:
        """Initialize the bootstrap stack.

        Args:
            scope: CDK scope
            construct_id: Stack identifier
            **kwargs: Additional stack properties
        """
        super().__init__(scope, construct_id, **kwargs)

        # Get environment from context
        environment = self.node.try_get_context("environment") or "dev"

        # Reference existing OIDC provider (created in orb-infrastructure)
        oidc_provider_arn = (
            "arn:aws:iam::432045270100:oidc-provider/token.actions.githubusercontent.com"
        )
        oidc_provider = iam.OpenIdConnectProvider.from_open_id_connect_provider_arn(
            self, "GitHubOIDCProvider", oidc_provider_arn
        )

        # Create project-specific deployment role
        github_role = iam.Role(
            self,
            "GitHubActionsRole",
            role_name=f"tr-dungeons-{environment}-github-actions",
            assumed_by=iam.FederatedPrincipal(
                oidc_provider.open_id_connect_provider_arn,
                conditions={
                    "StringEquals": {
                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                    },
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": (
                            "repo:com-terminal-realms/tr-dungeons:*"
                        )
                    },
                },
                assume_role_action="sts:AssumeRoleWithWebIdentity",
            ),
            description=f"GitHub Actions deployment role for TR-Dungeons {environment}",
            max_session_duration=cdk.Duration.hours(1),
        )

        # Grant permissions for CDK deployments
        github_role.add_managed_policy(
            iam.ManagedPolicy.from_aws_managed_policy_name("PowerUserAccess")
        )

        # Grant IAM permissions for CDK bootstrap and role management
        github_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "iam:CreateRole",
                    "iam:DeleteRole",
                    "iam:GetRole",
                    "iam:PutRolePolicy",
                    "iam:DeleteRolePolicy",
                    "iam:AttachRolePolicy",
                    "iam:DetachRolePolicy",
                    "iam:PassRole",
                    "iam:TagRole",
                    "iam:UntagRole",
                ],
                resources=["*"],
            )
        )

        # Store role ARN in SSM for other stacks to reference
        ssm.StringParameter(
            self,
            "DeploymentRoleArnParameter",
            parameter_name=f"/tr-dungeons/{environment}/deployment-role-arn",
            string_value=github_role.role_arn,
            description=f"GitHub Actions deployment role ARN for {environment}",
            tier=ssm.ParameterTier.STANDARD,
        )

        # Outputs
        cdk.CfnOutput(
            self,
            "GitHubActionsRoleArn",
            value=github_role.role_arn,
            description="ARN of the GitHub Actions deployment role",
            export_name=f"TRDungeonsGitHubActionsRoleArn-{environment}",
        )

        cdk.CfnOutput(
            self,
            "GitHubActionsRoleName",
            value=github_role.role_name,
            description="Name of the GitHub Actions deployment role",
        )
