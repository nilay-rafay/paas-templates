variable "region" {
  type        = string
  default     = "us-west-2"
}
variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
  default = "eks-managed-bootstrap-1"
}
variable "cluster_type" {
  type        = string
  description = "Type of the cluster"
  default = "eks"
}
variable "resource_group" {
  type        = string
  description = "Azure Resource Group Name"
  default = "dev-aks"
}
variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "rafay"
}
variable "rerun_trigger" {
  type = string
  default = "run1"
}
variable "cloud_credential" {
  description = "Cloud credentials of the Cluster"
  type        = string
  default     = "test"
}