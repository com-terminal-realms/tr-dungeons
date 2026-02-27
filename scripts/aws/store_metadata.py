#!/usr/bin/env python3
"""Store build metadata in DynamoDB."""

import argparse
import json
import sys
from datetime import datetime

import boto3
from botocore.exceptions import ClientError


def store_metadata(
    table_name: str,
    version: str,
    git_commit_sha: str,
    builds: dict,
    changelog: str,
    workflow_run_id: str,
    max_retries: int = 3,
) -> bool:
    """Store build metadata in DynamoDB table.
    
    Args:
        table_name: DynamoDB table name
        version: Build version (e.g., "0.4.1")
        git_commit_sha: Git commit SHA
        builds: Dictionary of platform -> build info
        changelog: Changelog text
        workflow_run_id: GitHub Actions workflow run ID
        max_retries: Maximum number of retry attempts
        
    Returns:
        True if write succeeded, False otherwise
    """
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    # Construct item
    item = {
        "version": version,
        "timestamp": timestamp,
        "git_commit_sha": git_commit_sha,
        "builds": builds,
        "changelog": changelog,
        "workflow_run_id": workflow_run_id,
        "created_at": timestamp,
        "updated_at": timestamp,
    }
    
    print(f"Storing metadata in DynamoDB table: {table_name}")
    print(f"  Version: {version}")
    print(f"  Commit: {git_commit_sha}")
    print(f"  Workflow: {workflow_run_id}")
    print(f"  Platforms: {', '.join(builds.keys())}")
    
    for attempt in range(1, max_retries + 1):
        try:
            table.put_item(Item=item)
            
            print(f"✅ Metadata stored successfully (attempt {attempt}/{max_retries})")
            return True
            
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            print(f"❌ Write failed (attempt {attempt}/{max_retries}): {error_code} - {error_msg}")
            
            if attempt == max_retries:
                print(f"❌ All {max_retries} write attempts failed")
                return False
            
            # Exponential backoff
            import time
            wait_time = 2 ** attempt
            print(f"  Retrying in {wait_time} seconds...")
            time.sleep(wait_time)
    
    return False


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Store build metadata in DynamoDB")
    parser.add_argument("--table", required=True, help="DynamoDB table name")
    parser.add_argument("--version", required=True, help="Build version")
    parser.add_argument("--commit", required=True, help="Git commit SHA")
    parser.add_argument("--builds", required=True, help="JSON string of builds dict")
    parser.add_argument("--changelog", required=True, help="Changelog text")
    parser.add_argument("--workflow-id", required=True, help="GitHub Actions workflow run ID")
    parser.add_argument("--retries", type=int, default=3, help="Max retry attempts")
    
    args = parser.parse_args()
    
    try:
        builds = json.loads(args.builds)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in --builds: {e}")
        return 1
    
    success = store_metadata(
        table_name=args.table,
        version=args.version,
        git_commit_sha=args.commit,
        builds=builds,
        changelog=args.changelog,
        workflow_run_id=args.workflow_id,
        max_retries=args.retries,
    )
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
