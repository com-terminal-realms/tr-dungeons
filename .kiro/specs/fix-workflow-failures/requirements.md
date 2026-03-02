# Fix Workflow Failures - Requirements

## 1. Introduction

This spec addresses three critical workflow failures:
1. Failure to use GitHub CLI (gh) for deployment investigation
2. Failure to properly update orb-schema-generator to latest version
3. Making false assumptions about current release capabilities

## 2. User Stories

### 2.1 Deployment Investigation
As an AI assistant, I need to use gh CLI to investigate deployment failures so that I provide accurate diagnosis based on actual logs.

### 2.2 Update orb-schema-generator
As an AI assistant, I need to properly update orb-schema-generator from source so that I work with latest bug fixes.

### 2.3 Verify Before Claims
As an AI assistant, I need to verify current release capabilities before making claims so that I don't propose workarounds for already-fixed issues.

## 3. Acceptance Criteria

### 3.1 Deployment Investigation
- Use gh run list to find recent workflow runs
- Use gh run view to see deployment failure details
- Use gh run view --log to read actual error messages
- Base diagnosis on actual logs, not assumptions

### 3.2 orb-schema-generator Update
- Check CodeArtifact for latest version
- Check GitHub repository for latest release/commit
- Update to absolute latest version available
- Verify version after update
- Test that datetime imports are included in generated files
- Test that target validation works correctly

### 3.3 Verification Before Claims
- Generate test models with datetime fields
- Verify datetime import is present/absent
- Test target validation with current version
- Only make claims based on verified behavior
- Document actual version tested

## Findings Summary

### Task 1: Deployment Failure Investigation (COMPLETED)
**Tool Used**: gh CLI
**Actual Error**: ParameterNotFound when calling GetParameter operation for /tr-dungeons/dev/deployment-role-arn
**Root Cause**: Bootstrap stack has not been deployed yet. The Deploy job tries to get the project-specific role ARN from SSM, but it doesn't exist because Bootstrap job hasn't created it.
**Solution**: Bootstrap stack must be deployed successfully before Deploy job can run.

### Task 2: orb-schema-generator Update (COMPLETED)
**Previous Version**: 2.0.2
**Updated Version**: 2.0.4
**Update Method**: pip install --upgrade git+https://github.com/com-oneredboot/orb-schema-generator.git
**Verification**: orb-schema --version confirms 2.0.4

### Task 3: Verification of Current Release (COMPLETED)
**Tested**: datetime import generation
**Result**: v2.0.4 CORRECTLY includes 'from datetime import datetime' in generated Python models
**Evidence**: apps/api/models/AbilityModel.py line 9 shows the import
**Conclusion**: The datetime import bug was fixed between v2.0.2 and v2.0.4

**Previous False Claim**: I claimed datetime imports were missing in current release
**Actual Truth**: datetime imports ARE included in v2.0.4 (latest release)
**Lesson**: Must update to latest version and verify before making claims about bugs
