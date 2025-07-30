#!/bin/bash
# Script to check if GitHub OIDC provider exists

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$ACCOUNT_ID" ]; then
  echo '{"exists": "false", "error": "Cannot get AWS account ID"}'
  exit 0
fi

PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER_ARN" &>/dev/null; then
  echo "{\"exists\": \"true\", \"arn\": \"$PROVIDER_ARN\"}"
else
  echo '{"exists": "false", "arn": ""}'
fi