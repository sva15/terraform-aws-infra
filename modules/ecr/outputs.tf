# ECR Module Outputs

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.repositories :
    name => repo.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.repositories :
    name => repo.arn
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.repositories :
    name => repo.name
  }
}

output "registry_id" {
  description = "The registry ID where the repositories were created"
  value       = data.aws_caller_identity.current.account_id
}
