# Game Build Distribution System

Automated CI/CD pipeline for building and distributing TR-Dungeons game builds across multiple platforms.

## Overview

The build distribution system automatically:
1. Builds the game for Windows, Linux, and macOS
2. Uploads builds to AWS S3 with versioned paths
3. Generates presigned download URLs (7-day expiration)
4. Stores build metadata in DynamoDB
5. Notifies subscribers via SQS/SNS

## Triggering a Build

### Automatic Trigger (Recommended)

Push a release tag to trigger the workflow:

```bash
# Create and push a release tag
git tag -a v0.5.1-release -m "Release version 0.5.1"
git push origin v0.5.1-release
```

**Tag Format:** `v<major>.<minor>.<patch>-release`

The workflow will:
- Extract version from tag (e.g., `v0.5.1-release` → `0.5.1`)
- Generate changelog from git commits since last release
- Build all platforms in parallel
- Upload and notify automatically

### Manual Trigger

Trigger the workflow manually from GitHub Actions UI:

1. Go to **Actions** → **Build and Distribute Game**
2. Click **Run workflow**
3. Enter:
   - **Version:** e.g., `0.5.1`
   - **Changelog:** Release notes text
4. Click **Run workflow**

## Build Process

### Workflow Steps

1. **Setup** (1 min)
   - Extract version and metadata
   - Prepare build matrix

2. **Build Platforms** (parallel, ~3-5 min each)
   - Windows: `.exe` executable
   - Linux: `.x86_64` executable
   - macOS: `.zip` bundle (universal binary)

3. **Upload and Notify** (2-3 min)
   - Upload artifacts to S3
   - Generate presigned URLs
   - Store metadata in DynamoDB
   - Send notifications to SQS

**Total Time:** ~8-10 minutes

### Build Artifacts

Artifacts are stored in S3 with this structure:

```
s3://tr-dungeons-builds/
└── builds/
    └── v0.5.1/
        ├── windows/
        │   └── tr-dungeons-windows.exe
        ├── linux/
        │   └── tr-dungeons-linux.x86_64
        └── macos/
            └── tr-dungeons-macos.zip
```

## Download Links

### Presigned URLs

All download links are presigned URLs that:
- Expire after **7 days**
- Use AWS Signature Version 4
- Work without AWS credentials
- Are included in notification emails

### Getting Download Links

**From GitHub Actions:**
1. Go to workflow run
2. View **Summary** tab
3. Click download links

**From Notification Email:**
- Subscribers receive email with all platform links
- Links expire in 7 days

**From DynamoDB:**
```bash
aws dynamodb get-item \
  --table-name tr-dungeons-build-metadata \
  --key '{"version": {"S": "0.5.1"}}'
```

## Subscriber Management

### Add Email Subscriber

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:tr-dungeons-build-releases \
  --protocol email \
  --notification-endpoint your-email@example.com
```

Confirm subscription via email link.

### Add SMS Subscriber

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:tr-dungeons-build-releases \
  --protocol sms \
  --notification-endpoint +1234567890
```

### List Subscribers

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:tr-dungeons-build-releases
```

### Unsubscribe

```bash
aws sns unsubscribe \
  --subscription-arn <subscription-arn>
```

## Notification Format

### Email Notification

```
Subject: TR-Dungeons v0.5.1 is now available!

Hi there,

A new version of Terminal Realms: Dungeons is ready to download!

Version: 0.5.1
Released: 2024-02-27T10:30:00Z

What's New:
- Added loot system with auto-collect
- Fixed combat bugs
- Improved performance

Download for your platform:
- Windows: https://tr-dungeons-builds.s3.amazonaws.com/... (expires in 7 days)
- Linux: https://tr-dungeons-builds.s3.amazonaws.com/... (expires in 7 days)
- macOS: https://tr-dungeons-builds.s3.amazonaws.com/... (expires in 7 days)

Happy dungeon crawling!
- The TR-Dungeons Team
```

### SMS Notification

```
TR-Dungeons v0.5.1 released! Download at: [short link]
```

## Version Retention

The system automatically retains the **last 5 versions** and deletes older versions.

### Lifecycle Policy

- **Retention:** 5 most recent versions
- **Cleanup:** Automatic via S3 lifecycle rules
- **Metadata:** Updated in DynamoDB when versions are deleted

### Manual Cleanup

To manually delete old versions:

```bash
# List all versions
aws s3api list-object-versions \
  --bucket tr-dungeons-builds \
  --prefix builds/

# Delete specific version
aws s3 rm s3://tr-dungeons-builds/builds/v0.4.0/ --recursive
```

## Troubleshooting

### Build Failures

**Check workflow logs:**
1. Go to **Actions** → Failed workflow run
2. Click on failed job
3. Review error logs

**Common issues:**
- **Export templates missing:** Workflow downloads them automatically
- **Godot version mismatch:** Update `GODOT_VERSION` in workflow
- **Build timeout:** Increase timeout in workflow (default: 10 min)

### Upload Failures

**S3 upload errors:**
- Check AWS credentials are configured
- Verify IAM role has S3 write permissions
- Check S3 bucket exists and is accessible

**Retry logic:**
- Uploads retry 3 times with exponential backoff
- Check logs for retry attempts

### Notification Failures

**SQS send errors:**
- Verify queue URL is correct
- Check IAM role has SQS send permissions
- Check dead letter queue for failed messages

**SNS delivery issues:**
- Verify subscribers are confirmed
- Check SNS topic permissions
- Review CloudWatch Logs for delivery failures

### Missing Download Links

**If links are missing:**
1. Check S3 bucket for uploaded files
2. Verify presigned URL generation succeeded
3. Check DynamoDB for metadata entry
4. Regenerate URLs manually if needed:

```bash
python3 scripts/aws/generate_presigned_url.py \
  --bucket tr-dungeons-builds \
  --key builds/v0.5.1/windows/tr-dungeons-windows.exe
```

## Infrastructure

### AWS Resources

- **S3 Bucket:** `tr-dungeons-builds`
- **SQS Queue:** `tr-dungeons-build-notifications`
- **SNS Topic:** `tr-dungeons-build-releases`
- **DynamoDB Table:** `tr-dungeons-build-metadata`
- **IAM Role:** `tr-dungeons-github-actions-role`

### Deploy Infrastructure

```bash
cd infrastructure/cdk
pip install -r requirements.txt
cdk deploy TRDungeonsBuildDistribution
```

### Update Infrastructure

```bash
cd infrastructure/cdk
cdk diff TRDungeonsBuildDistribution
cdk deploy TRDungeonsBuildDistribution
```

## Monitoring

### CloudWatch Metrics

- Build success/failure rate
- Build duration per platform
- S3 upload size and duration
- SQS message delivery rate
- DynamoDB read/write latency

### CloudWatch Alarms

- Build failure rate > 10%
- Workflow duration > 10 minutes
- SQS dead letter queue depth > 0
- DynamoDB throttling events

### View Logs

```bash
# Workflow logs
aws logs tail /aws/tr-dungeons/build-distribution --follow

# S3 access logs
aws s3 ls s3://tr-dungeons-builds-logs/

# SQS message logs
aws sqs receive-message --queue-url <queue-url>
```

## Security

### IAM Permissions

The GitHub Actions role has least-privilege access:
- S3: Read/write to `tr-dungeons-builds` bucket only
- SQS: Send messages to notification queue only
- DynamoDB: Read/write to metadata table only

### Credential Management

- **GitHub Secrets:** Store AWS account ID and queue URL
- **OIDC Authentication:** No long-lived credentials
- **Presigned URLs:** Temporary access (7 days)
- **Log Masking:** Credentials masked in workflow logs

### S3 Bucket Security

- **Encryption:** S3-managed encryption (SSE-S3)
- **Public Access:** Blocked (presigned URLs only)
- **Versioning:** Enabled for rollback capability
- **Access Logs:** Optional (can be enabled)

## Cost Estimation

### Monthly Costs (estimated)

- **S3 Storage:** ~$0.50 (5 versions × 500MB × $0.023/GB)
- **S3 Requests:** ~$0.10 (PUT/GET requests)
- **Data Transfer:** ~$1.00 (downloads via presigned URLs)
- **DynamoDB:** ~$0.25 (on-demand, low traffic)
- **SQS/SNS:** ~$0.10 (low message volume)

**Total:** ~$2/month for typical usage

### Cost Optimization

- Use S3 lifecycle policies to delete old versions
- Enable S3 Intelligent-Tiering for long-term storage
- Use on-demand billing for DynamoDB (low traffic)
- Limit presigned URL expiration to reduce storage time

## Future Enhancements

- [ ] Add Lambda function for SNS notification formatting
- [ ] Add Lambda function for metadata expiration updates
- [ ] Add CloudWatch dashboard for monitoring
- [ ] Add webhook support for Discord/Slack notifications
- [ ] Add build caching to speed up workflow
- [ ] Add platform-specific build options
- [ ] Add automated testing before distribution
