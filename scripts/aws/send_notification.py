#!/usr/bin/env python3
"""Send build notification to SQS queue."""

import argparse
import json
import sys
from datetime import datetime

import boto3
from botocore.exceptions import ClientError


def send_notification(
    queue_url: str,
    version: str,
    git_commit_sha: str,
    changelog: str,
    builds: dict,
    max_retries: int = 3,
) -> bool:
    """Send build notification message to SQS queue.

    Args:
        queue_url: SQS queue URL
        version: Build version (e.g., "0.4.1")
        git_commit_sha: Git commit SHA
        changelog: Changelog text
        builds: Dictionary of platform -> build info
        max_retries: Maximum number of retry attempts

    Returns:
        True if send succeeded, False otherwise
    """
    sqs_client = boto3.client("sqs")

    # Construct message
    message = {
        "version": version,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "git_commit_sha": git_commit_sha,
        "changelog": changelog,
        "builds": builds,
    }

    message_body = json.dumps(message, indent=2)

    print(f"Sending notification to SQS queue: {queue_url}")
    print(f"  Version: {version}")
    print(f"  Commit: {git_commit_sha}")
    print(f"  Platforms: {', '.join(builds.keys())}")

    for attempt in range(1, max_retries + 1):
        try:
            response = sqs_client.send_message(
                QueueUrl=queue_url,
                MessageBody=message_body,
                MessageAttributes={
                    "version": {
                        "StringValue": version,
                        "DataType": "String",
                    },
                    "platforms": {
                        "StringValue": ",".join(builds.keys()),
                        "DataType": "String",
                    },
                },
            )

            message_id = response.get("MessageId", "unknown")
            print(
                f"✅ Notification sent successfully (attempt {attempt}/{max_retries})"
            )
            print(f"  Message ID: {message_id}")
            return True

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            print(
                f"❌ Send failed (attempt {attempt}/{max_retries}): {error_code} - {error_msg}"
            )

            if attempt == max_retries:
                print(f"❌ All {max_retries} send attempts failed")
                return False

            # Exponential backoff
            import time

            wait_time = 2**attempt
            print(f"  Retrying in {wait_time} seconds...")
            time.sleep(wait_time)

    return False


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Send build notification to SQS")
    parser.add_argument("--queue-url", required=True, help="SQS queue URL")
    parser.add_argument("--version", required=True, help="Build version")
    parser.add_argument("--commit", required=True, help="Git commit SHA")
    parser.add_argument("--changelog", required=True, help="Changelog text")
    parser.add_argument("--builds", required=True, help="JSON string of builds dict")
    parser.add_argument("--retries", type=int, default=3, help="Max retry attempts")

    args = parser.parse_args()

    try:
        builds = json.loads(args.builds)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in --builds: {e}")
        return 1

    success = send_notification(
        queue_url=args.queue_url,
        version=args.version,
        git_commit_sha=args.commit,
        changelog=args.changelog,
        builds=builds,
        max_retries=args.retries,
    )

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
