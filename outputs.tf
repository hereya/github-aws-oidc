output "roleArn" {
  description = "The ARN of the role that can be assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

output "roleName" {
  value       = aws_iam_role.github_actions.name
  description = "The name of the role that can be assumed by GitHub Actions."
}

output "githubSecretName" {
  value       = var.githubSecretName
  description = "The name of the secret that contains the role ARN."
}

output "githubAwsRegionVarName" {
  value       = github_actions_variable.aws_region[0].variable_name
  description = "The name of the GitHub variable that contains the AWS region."
}

output "repositories" {
  value       = var.repositories
  description = "The repositories that are allowed to be deployed."
}
