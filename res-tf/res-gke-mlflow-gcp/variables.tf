variable "hserver" {
  description = "Kubeconfig server"
  type        = string
}

variable "clientcertificatedata" {
  description = "Kubeconfig client-certificate-data"
  type        = string
}

variable "clientkeydata" {
  description = "Kubeconfig client-key-data"
  type        = string
}

variable "certificateauthoritydata" {
  description = "Kubeconfig certificate-authority-data"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig"
  type        = string
}

variable "gcp_project_id" {
  description = "The ID of the project in which to create resources."
  type        = string
}

variable "gcp_region" {
  description = "The region in which to create resources."
  type        = string
  default     = "us-central1"
}


variable "mlflow_mysql_instance" {
  description = "The IP address of the Cloud SQL instance."
  type        = string
  nullable    = false
}


variable "mlflow_mysql_db" {
  description = "The name of the database to use."
  type        = string
  default     = "mlflow"
}

variable "mlflow_mysql_user" {
  description = "The username to use when connecting to the Cloud SQL instance."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "mlflow_mysql_pass" {
  description = "The password to use when connecting to the Cloud SQL instance."
  type        = string
  default     = "mlflow"
  sensitive   = true
  nullable    = false
}

variable "gcp_mlflow_bucket" {
  description = "The name of the GCS bucket to use for MLflow tracking."
  type        = string
  default     = "mlflow_bucket"
  nullable    = false
}

variable "gcp_mlflow_sa" {
  description = "The name of the GCP service account to use for MLflow tracking."
  type        = string
  default     = "mlflow-tracking-new"
  nullable    = false
}

variable "k8s_mlflow_namespace" {
  description = "The namespace in which to create resources."
  type        = string
  default     = "mlflow"
  nullable    = false
}

variable "k8s_mlflow_sa" {
  description = "The name of the Kubernetes service account to use for MLflow tracking."
  type        = string
  default     = "mlflow-tracking"
  nullable    = false
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "sqladmin.googleapis.com",
  ]
}
