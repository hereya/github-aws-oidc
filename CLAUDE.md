# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform module that sets up GitHub Actions OIDC (OpenID Connect) authentication with AWS. It creates the necessary AWS IAM roles and GitHub secrets to allow GitHub Actions workflows to assume AWS roles without storing long-lived credentials.

## Key Files

- `main.tf` - Core Terraform configuration defining the OIDC provider, IAM role, and GitHub secrets
- `variables.tf` - Input variables for customizing the module
- `outputs.tf` - Outputs including the IAM role ARN and name

## Common Commands

### Terraform Initialization and Planning
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### Formatting and Validation
```bash
terraform fmt
terraform validate
```

## Architecture

The module creates:

1. **AWS IAM OIDC Provider** - Trusts GitHub's OIDC token endpoint with proper thumbprint verification
2. **IAM Assume Role Policy** - Restricts which GitHub repositories and branches/tags can assume the role
3. **IAM Role** - Created with admin permissions (full access to all AWS resources)
4. **GitHub Secrets** - Automatically creates secrets in specified repositories containing the role ARN

## Key Configuration Points

- **Repositories**: Comma-separated list in format "owner/repo" (e.g., "myorg/myrepo,myorg/otherrepo")
- **Allowed Branches**: By default allows all branches (`*`) and tags starting with `v*`
- **GitHub Secret Name**: Default is `HEREYA_GITHUB_ACTIONS_AWS_ROLE`
- **Admin Permissions**: The created role has full AWS admin access - consider restricting for production use

## Security Considerations

The IAM role created has full admin permissions (`*` actions on `*` resources). For production environments, you should modify the `admin_permission` policy in main.tf:74-84 to follow the principle of least privilege.