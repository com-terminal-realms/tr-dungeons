#!/usr/bin/env python3
"""Generate presigned URLs for S3 objects with 7-day expiration."""

import argparse
import sys
from datetime import datetime, timedelta

import boto3
from botocore.exceptions import ClientError


# 7-day expiration (in seconds)
EXPIRATION_SECONDS = int(timedelta(days=7).total_seconds())


def generate_presigned_url(
    bucket_name: str,
    s3_key: str,
    expiration_seconds: int = EXPIRATION_SECONDS,
) -> str:
    """Generate a presigned URL for downloading an S3 object.
    
    Args:
        bucket_name: S3 bucket name
        s3_key: S3 object key
        expiration_seconds: URL expiration time in seconds (default: 7 days)
        
    Returns:
        Presigned URL string
        
    Raises:
        ClientError: If URL generation fails
    """
    s3_client = boto3.client("s3", config=boto3.session.Config(signature_version="s3v4"))
    
    try:
        url = s3_client.generate_presigned_url(
            "get_object",
            Params={
                "Bucket": bucket_name,
                "Key": s3_key,
            },
            ExpiresIn=expiration_seconds,
        )
        
        # Calculate expiration timestamp
        expires_at = datetime.utcnow() + timedelta(seconds=expiration_seconds)
        
        print(f"✅ Generated presigned URL for s3://{bucket_name}/{s3_key}")
        print(f"  Expires at: {expires_at.isoformat()}Z")
        print(f"  Expiration: {expiration_seconds} seconds ({expiration_seconds / 86400:.1f} days)")
        
        return url
        
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_msg = e.response.get("Error", {}).get("Message", str(e))
        print(f"❌ Failed to generate presigned URL: {error_code} - {error_msg}")
        raise


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Generate presigned URLs for S3 objects")
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key", required=True, help="S3 object key")
    parser.add_argument(
        "--expiration",
        type=int,
        default=EXPIRATION_SECONDS,
        help=f"Expiration time in seconds (default: {EXPIRATION_SECONDS})",
    )
    
    args = parser.parse_args()
    
    try:
        url = generate_presigned_url(
            bucket_name=args.bucket,
            s3_key=args.key,
            expiration_seconds=args.expiration,
        )
        print(f"\nPresigned URL:\n{url}")
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
