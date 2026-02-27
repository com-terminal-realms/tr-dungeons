#!/usr/bin/env python3
"""CDK app for TR-Dungeons infrastructure."""

import aws_cdk as cdk
from stacks.build_distribution_stack import BuildDistributionStack


app = cdk.App()

BuildDistributionStack(
    app,
    "TRDungeonsBuildDistribution",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region") or "us-east-1",
    ),
    description="Game build distribution infrastructure for TR-Dungeons",
)

app.synth()
