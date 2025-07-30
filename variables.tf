variable "repositories" {
  description = "List of repositories that are allowed to be deployed"
  type = string # Format: comma separated list of "owner/repo"
}

variable "organization" {
  description = "Name of the organization that is allowed to be deployed"
  type        = string
}

variable "githubVarSuffix" {
  description = "Suffix for the GitHub variables"
  type        = string
  default     = ""
}

variable "githubSecretName" {
  description = "Name of the secret to create in the GitHub repository"
  type        = string
  default     = "HEREYA_GITHUB_ACTIONS_AWS_ROLE"
}

variable "roleNamePrefix" {
  description = "Prefix for the role name"
  type        = string
  default     = "hereya-github-actions-aws-role"
}

variable "allowedBranches" {
  description = "List of branches and tags that are allowed to be deployed"
  type = list(object(
    {
      type = string # "heads" for branches or "tags" for tags
      ref  = string # branch name or tag name
    }
  ))
  default = [
    {
      type = "heads" # "heads" for branches or "tags" for tags
      ref  = "*"
    },
    {
      type = "tags" # "heads" for branches or "tags" for tags
      ref  = "v*"
    }
  ]
}
