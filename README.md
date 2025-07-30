# GitHub Actions OIDC Provider for AWS

This Terraform module sets up OpenID Connect (OIDC) authentication between GitHub Actions and AWS, allowing GitHub Actions workflows to assume AWS IAM roles without storing long-lived credentials.

## Features

- ✅ Creates AWS IAM OIDC provider for GitHub Actions (or reuses existing one)
- ✅ Sets up IAM role with customizable permissions
- ✅ Automatically creates GitHub secrets with the role ARN
- ✅ Supports multiple repositories and branch/tag restrictions
- ✅ Handles existing OIDC provider gracefully

## Prerequisites

- Terraform >= 1.2.0 or OpenTofu
- AWS credentials with permissions to create IAM resources
- GitHub token with permissions to create repository secrets

## Usage

### Basic Example

```hcl
module "github_oidc" {
  source = "./path-to-module"
  
  organization = "myorg"
  repositories = "myorg/repo1,myorg/repo2"
}
```

### Advanced Example

```hcl
module "github_oidc" {
  source = "./path-to-module"
  
  organization     = "myorg"
  repositories     = "myorg/frontend,myorg/backend,myorg/infrastructure"
  roleNamePrefix   = "custom-github-actions-role"
  githubSecretName = "AWS_DEPLOY_ROLE"
  
  allowedBranches = [
    {
      type = "heads"
      ref  = "main"
    },
    {
      type = "heads"
      ref  = "develop"
    },
    {
      type = "tags"
      ref  = "v*"
    }
  ]
}
```

## Configuration

### Required Variables

| Name | Description | Type | Example |
|------|-------------|------|---------|
| `organization` | GitHub organization name | `string` | `"myorg"` |
| `repositories` | Comma-separated list of repositories | `string` | `"myorg/repo1,myorg/repo2"` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `githubSecretName` | Name of the GitHub secret to create | `string` | `"HEREYA_GITHUB_ACTIONS_AWS_ROLE"` |
| `roleNamePrefix` | Prefix for the IAM role name | `string` | `"hereya-github-actions-aws-role"` |
| `allowedBranches` | List of allowed branches and tags | `list(object)` | All branches (`*`) and tags starting with `v*` |

### Outputs

| Name | Description |
|------|-------------|
| `roleArn` | ARN of the IAM role that can be assumed by GitHub Actions |
| `roleName` | Name of the created IAM role |
| `githubSecretName` | Name of the GitHub secret containing the role ARN |

## GitHub Actions Workflow Example

Once the module is applied, use the created role in your GitHub Actions workflow:

```yaml
name: Deploy to AWS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.HEREYA_GITHUB_ACTIONS_AWS_ROLE }}
          aws-region: eu-west-1
      
      - name: Deploy
        run: |
          # Your deployment commands here
          aws s3 ls  # Example command
```

## Security Considerations

⚠️ **Important**: By default, this module creates an IAM role with full administrative permissions (`*` actions on `*` resources). This is suitable for development but should be restricted for production use.

To customize permissions, modify the `admin_permission` policy in `main.tf`:

```hcl
data "aws_iam_policy_document" "admin_permission" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "cloudformation:*",
      "lambda:*"
    ]
    resources = ["*"]
  }
}
```

## Handling Existing OIDC Provider

The module automatically detects if a GitHub OIDC provider already exists in your AWS account and reuses it. This prevents the "EntityAlreadyExists" error when multiple modules or deployments try to create the same provider.

If you encounter issues with the OIDC provider detection, you can:

1. Check if the provider exists:
   ```bash
   aws iam get-open-id-connect-provider \
     --open-id-connect-provider-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com"
   ```

2. If needed, manually import the existing provider:
   ```bash
   tofu import aws_iam_openid_connect_provider.github_actions \
     arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
   ```

## Requirements

### Providers

| Name | Version |
|------|---------|
| terraform | >= 1.2.0, < 2.0.0 |
| aws | ~> 4.0 |
| github | ~> 5.23 |
| external | any |
| tls | any |

### Resources Created

- AWS IAM OIDC Provider (if not exists)
- AWS IAM Role with assume role policy
- AWS IAM Role Policy (admin by default)
- GitHub Actions secrets in specified repositories

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if applicable]