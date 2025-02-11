# Define variables
variable "input1" {
  description = "First input"
  type        = string
}

variable "input2" {
  description = "Second input"
  type        = string
}

variable "input3" {
  description = "Third input"
  type        = string
}

variable "input4" {
  description = "Fourth input"
  type        = string
}

variable "run_strategy" {
  description = "Run strategy"
  type        = string
}

variable "cluster_name" {
  description = "cluster name"
  type        = string
}

# Output the values of the variables
output "output1" {
  value = var.input1
}

output "output2" {
  value = var.input2
}

output "output3" {
  value = var.input3
}

output "output4" {
  value = var.input4
}

output "output_run_strategy" {
  value = var.run_strategy
}

output "cluster_name" {
  value = var.cluster_name
}
