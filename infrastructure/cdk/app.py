#!/usr/bin/env python3
"""CDK app for TR-Dungeons infrastructure."""

import aws_cdk as cdk

from stacks.bootstrap_stack import BootstrapStack
from stacks.infrastructure_stack import InfrastructureStack

app = cdk.App()

# Get environment from context
environment = app.node.try_get_context("environment") or "dev"

# Bootstrap stack - creates project-specific deployment role
BootstrapStack(
    app,
    f"TRDungeonsBootstrap-{environment}",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region") or "us-east-1",
    ),
    description=f"Bootstrap infrastructure for TR-Dungeons {environment}",
)

# Infrastructure stack - core application resources
InfrastructureStack(
    app,
    f"TRDungeonsInfrastructure-{environment}",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region") or "us-east-1",
    ),
    description=f"Core infrastructure for TR-Dungeons {environment}",
)

app.synth()
