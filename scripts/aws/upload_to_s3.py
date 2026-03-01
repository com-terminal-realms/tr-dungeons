#!/usr/bin/env python3
"""Upload build artifacts to S3 with multipart upload support."""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

# Multipart upload threshold (100MB)
MULTIPART_THRESHOLD = 100 * 1024 * 1024
CHUNK_SIZE = 10 * 1024 * 1024  # 10MB chunks


def upload_file(
    file_path: str,
    bucket_name: str,
    s3_key: str,
    version: str,
    platform: str,
    git_commit_sha: str,
    max_retries: int = 3,
) -> bool:
    """Upload a file to S3 with metadata and retry logic.

    Args:
        file_path: Local path to the file to upload
        bucket_name: S3 bucket name
        s3_key: S3 object key (path in bucket)
        version: Build version (e.g., "0.4.1")
        platform: Platform name (windows, linux, macos)
        git_commit_sha: Git commit SHA
        max_retries: Maximum number of retry attempts

    Returns:
        True if upload succeeded, False otherwise
    """
    s3_client = boto3.client("s3")
    file_size = os.path.getsize(file_path)

    # Determine content type based on file extension
    content_type_map = {
        ".exe": "application/x-msdownload",
        ".x86_64": "application/x-executable",
        ".zip": "application/zip",
    }
    file_ext = Path(file_path).suffix
    content_type = content_type_map.get(file_ext, "application/octet-stream")

    # Metadata for S3 object
    metadata = {
        "version": version,
        "platform": platform,
        "build-timestamp": datetime.utcnow().isoformat() + "Z",
        "git-commit-sha": git_commit_sha,
    }

    print(f"Uploading {file_path} to s3://{bucket_name}/{s3_key}")
    print(f"  File size: {file_size / (1024 * 1024):.2f} MB")
    print(f"  Content type: {content_type}")
    print(f"  Metadata: {metadata}")

    # Use multipart upload for large files
    use_multipart = file_size > MULTIPART_THRESHOLD

    for attempt in range(1, max_retries + 1):
        try:
            if use_multipart:
                print(f"  Using multipart upload (attempt {attempt}/{max_retries})")
                _multipart_upload(
                    s3_client, file_path, bucket_name, s3_key, content_type, metadata
                )
            else:
                print(f"  Using single-part upload (attempt {attempt}/{max_retries})")
                with open(file_path, "rb") as f:
                    s3_client.put_object(
                        Bucket=bucket_name,
                        Key=s3_key,
                        Body=f,
                        ContentType=content_type,
                        Metadata=metadata,
                    )

            print(f"✅ Upload successful: s3://{bucket_name}/{s3_key}")
            return True

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            print(
                f"❌ Upload failed (attempt {attempt}/{max_retries}): {error_code} - {error_msg}"
            )

            if attempt == max_retries:
                print(f"❌ All {max_retries} upload attempts failed")
                return False

            # Exponential backoff
            import time

            wait_time = 2**attempt
            print(f"  Retrying in {wait_time} seconds...")
            time.sleep(wait_time)

    return False


def _multipart_upload(
    s3_client,
    file_path: str,
    bucket_name: str,
    s3_key: str,
    content_type: str,
    metadata: dict,
) -> None:
    """Perform multipart upload for large files."""
    # Initiate multipart upload
    response = s3_client.create_multipart_upload(
        Bucket=bucket_name,
        Key=s3_key,
        ContentType=content_type,
        Metadata=metadata,
    )
    upload_id = response["UploadId"]

    try:
        parts = []
        part_number = 1
        file_size = os.path.getsize(file_path)

        with open(file_path, "rb") as f:
            while True:
                chunk = f.read(CHUNK_SIZE)
                if not chunk:
                    break

                # Upload part
                part_response = s3_client.upload_part(
                    Bucket=bucket_name,
                    Key=s3_key,
                    PartNumber=part_number,
                    UploadId=upload_id,
                    Body=chunk,
                )

                parts.append(
                    {
                        "PartNumber": part_number,
                        "ETag": part_response["ETag"],
                    }
                )

                # Progress reporting
                bytes_uploaded = part_number * CHUNK_SIZE
                progress = min(100, (bytes_uploaded / file_size) * 100)
                print(f"  Progress: {progress:.1f}% (part {part_number})")

                part_number += 1

        # Complete multipart upload
        s3_client.complete_multipart_upload(
            Bucket=bucket_name,
            Key=s3_key,
            UploadId=upload_id,
            MultipartUpload={"Parts": parts},
        )

    except Exception as e:
        # Abort multipart upload on error
        print(f"  Aborting multipart upload due to error: {e}")
        s3_client.abort_multipart_upload(
            Bucket=bucket_name,
            Key=s3_key,
            UploadId=upload_id,
        )
        raise


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Upload build artifacts to S3")
    parser.add_argument("file_path", help="Path to file to upload")
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key", required=True, help="S3 object key")
    parser.add_argument("--version", required=True, help="Build version")
    parser.add_argument(
        "--platform", required=True, help="Platform (windows, linux, macos)"
    )
    parser.add_argument("--commit", required=True, help="Git commit SHA")
    parser.add_argument("--retries", type=int, default=3, help="Max retry attempts")

    args = parser.parse_args()

    if not os.path.exists(args.file_path):
        print(f"❌ Error: File not found: {args.file_path}")
        return 1

    success = upload_file(
        file_path=args.file_path,
        bucket_name=args.bucket,
        s3_key=args.key,
        version=args.version,
        platform=args.platform,
        git_commit_sha=args.commit,
        max_retries=args.retries,
    )

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
