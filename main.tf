terraform {
  required_version = ">=1.2.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~>5.23"
    }
  }
}

provider "aws" {
}

provider "github" {
  owner = var.organization
}

data "aws_region" "current" {}  

locals {
  allowedRepositories = [
    for repo in split(",", var.repositories) : {
      owner = split("/", repo)[0]
      name  = split("/", repo)[1]
    }
  ]

  secretName = var.githubSecretName != null ? var.githubSecretName : "HEREYA_GITHUB_ACTIONS_AWS_ROLE${var.githubVarSuffix}"
  awsRegionVarName = "AWS_REGION${var.githubVarSuffix}"
}

# Fetch GitHub OIDC's thumbprint
data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

# Check if OIDC provider already exists
data "external" "oidc_check" {
  program = ["${path.module}/oidc_check.sh"]
}

locals {
  oidc_exists = data.external.oidc_check.result["exists"] == "true"
  existing_oidc_arn = data.external.oidc_check.result["arn"]
}

# Create the IAM OIDC provider for GitHub Actions (only if it doesn't exist)
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = local.oidc_exists ? 0 : 1
  
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github_oidc.certificates.0.sha1_fingerprint
  ]
}

# Get reference to the OIDC provider (either existing or newly created)
locals {
  github_oidc_provider_arn = local.oidc_exists ? local.existing_oidc_arn : aws_iam_openid_connect_provider.github_actions[0].arn
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for a in local.allowed_branches_ref :
        "repo:${a.owner}/${a.name}:ref:refs/${a.type}/${a.ref}"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name_prefix        = var.roleNamePrefix
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "admin_permission" {
  statement {
    effect  = "Allow"
    actions = [
      "*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "admin" {
  policy = data.aws_iam_policy_document.admin_permission.json
  role   = aws_iam_role.github_actions.id
}

resource "github_actions_secret" "role_arn" {
  for_each = toset([
    for repo in local.allowedRepositories : repo.name
  ])

  repository      = each.value
  secret_name     = var.githubSecretName
  plaintext_value = aws_iam_role.github_actions.arn
}

# create variable AWS_REGION in each repository
resource "github_actions_variable" "aws_region" {
  for_each = toset([
    for repo in local.allowedRepositories : repo.name
  ])

  repository      = each.value
  variable_name   = local.awsRegionVarName
  value           = data.aws_region.current.name
}

locals {
  allowed_branches_ref = concat([
    for repo in local.allowedRepositories : [
      for branch in var.allowedBranches : {
        owner = repo.owner
        name  = repo.name
        type  = branch.type
        ref   = branch.ref
      }
    ]
  ]...)
}
