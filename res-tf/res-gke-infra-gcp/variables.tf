variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string

  validation {
    condition = (
      // Validate that the project ID follows these rules:
      // - Must start with a lowercase letter
      // - Can contain lowercase letters, digits, dashes, and underscores
      // - Must be between 6 and 30 characters long
      // - Cannot start or end with a dash or underscore
      can(regex("^[a-z][a-z0-9_-]{5,28}[a-z0-9]$", var.gcp_project_id)) &&
      length(var.gcp_project_id) <= 30
    )
    
    error_message = "GCP project ID contains invalid character(s). Valid characters are [a-z0-9] and [-_], except at the beginning or the end. Minimum and maximum characters allowed are 6 and 30."
  }
}

variable "gcp_region" {
  description = "The GCP region"
  type        = string
  default     = "us-west1"

  validation {
    condition = (
      // Validate that the region follows the correct format:
      // - Must start with a continent identifier (us, europe, asia, southamerica)
      // - Followed by a hyphen
      // - Must have a lowercase letter sequence and may end with digits
      can(regex("^(us|europe|asia|southamerica)-[a-z]+[0-9]*$", var.gcp_region)) &&

      // Ensure the length of the region string does not exceed 20 characters
      length(var.gcp_region) <= 20
    )
    
    error_message = "GCP region format is invalid. Ensure it follows the correct format (e.g., us-west1). Maximum charcters allowed are 20."
  }
}


variable "gcp_zone" {
  description = "The GCP zone where resources will be created"
  type        = string
  default     = "us-west1-c"

  validation {
    condition = contains([
      "us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f",
      "us-east1-b", "us-east1-c", "us-east1-d", "us-east4-a", "us-east4-b",
      "us-east4-c", "us-west1-a", "us-west1-b", "us-west1-c", "us-west2-a",
      "us-west2-b", "us-west2-c", "us-west3-a", "us-west3-b", "us-west3-c",
      "us-west4-a", "us-west4-b", "us-west4-c", "northamerica-northeast1-a",
      "southamerica-east1-a", "europe-west1-b", "europe-west1-c", "europe-west1-d",
      "europe-west2-a", "europe-west2-b", "europe-west2-c", "europe-west3-a",
      "europe-west3-b", "europe-west3-c", "europe-west4-a", "europe-west4-b",
      "europe-west4-c", "europe-west6-a", "europe-central2-a", "asia-east1-a",
      "asia-east1-b", "asia-east1-c", "asia-east2-a", "asia-east2-b",
      "asia-northeast1-a", "asia-northeast1-b", "asia-northeast1-c",
      "asia-northeast2-a", "asia-northeast2-b", "asia-northeast3-a",
      "asia-south1-a", "asia-south1-b", "asia-south2-a", "asia-southeast1-a",
      "asia-southeast1-b", "asia-southeast2-a", "australia-southeast1-a",
      "australia-southeast2-a"
    ], var.gcp_zone)

    error_message = "GCP zone contains invalid value. Valid format is <region>-<zone>, e.g., us-west1-a. Check for valid zones in GCP documentation."
  }
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  nullable    = false

  validation {
    condition = (
      // Ensure the cluster name is not empty
      length(var.gke_cluster_name) > 0 &&
      
      // Ensure the length is between 3 and 30 characters
      length(var.gke_cluster_name) >= 3 && length(var.gke_cluster_name) <= 63
    )

    error_message = "GKE cluster name contains invalid character(s). Valid characters are [a-z0-9-], except at the beginning or the end. Minimum and maximum characters allowed are 3 and 63."
  }
}

variable "gcp_sql_instance_name" {
  description = "The name of the Cloud SQL instance"
  type        = string

  validation {
    condition = (
      // Ensure the name is not empty
      length(var.gcp_sql_instance_name) > 0 &&

      // Length between 3 and 63 characters
      length(var.gcp_sql_instance_name) >= 3 && length(var.gcp_sql_instance_name) <= 63 &&

      // Validate format:
      // - Must start with a letter
      // - Can contain letters, numbers, hyphens, underscores, and periods
      // - Must end with a letter or number
      can(regex("^[a-zA-Z][a-zA-Z0-9_.-]*[a-zA-Z0-9]$", var.gcp_sql_instance_name)) &&

      // Ensure no consecutive special characters
      !can(regex("[.-]{2}", var.gcp_sql_instance_name)) &&

      // Ensure no leading or trailing special characters
      !can(regex("^[.-]|[.-]$", var.gcp_sql_instance_name))
    )

    error_message = "Cloud SQL instance name contains invalid character(s). Valid characters are [a-zA-Z0-9] and [-_]. Minimum and maximum characters allowed are 3 and 63. It must start with a letter and end with a letter or number, and cannot have consecutive special characters or start/end with a special character."
  }
}


variable "gcp_sql_root_password" {
  description = "The root password for the SQL instance"
  type        = string
  sensitive   = true

  validation {
    condition = (
      // Ensure the password is between 8 and 20 characters long
      length(var.gcp_sql_root_password) >= 8 &&
      length(var.gcp_sql_root_password) <= 20 &&
      // Ensure the password is not empty
      var.gcp_sql_root_password != ""
    )
    
    error_message = "Root password is invalid. Minimum and maximum characters allowed are 8 and 20. It cannot be empty"
  }
}

variable "gcp_sql_user_name" {
  description = "The SQL user name"
  type        = string
  default     = "mlops-user"

  validation {
    condition = (
      // Check that the SQL user name matches the allowed format
      // The regex allows letters, numbers, underscores, and dashes, with a length of 1 to 30 characters
      can(regex("^[a-zA-Z0-9_-]{1,30}$", var.gcp_sql_user_name))
    )
    
    error_message = "SQL user name contains invalid character(s). Valid characters are [a-zA-Z0-9] and [-_]. Minimum and maximum characters allowed are 30."
  }
}

variable "gcp_sql_user_password" {
  description = "The SQL user password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      // Ensure the SQL user password meets length requirements
      // The password must be between 8 and 20 characters long and cannot be empty
      length(var.gcp_sql_user_password) >= 8 && 
      length(var.gcp_sql_user_password) <= 20 && 
      var.gcp_sql_user_password != ""
    )
    
    error_message = "SQL User password is invalid. Minimum and maximum characters allowed are 8 and 20. It cannot be empty."
  }
}


variable "gcp_sql_instance_tier" {
  description = "The tier of the SQL instance"
  type        = string
  default     = "db-f1-micro"

  validation {
    # Ensure the provided tier is one of the valid Google Cloud SQL instance tiers
    condition = contains([
      "db-f1-micro",
      "db-g1-small",
      "db-n1-standard-1",
      "db-n1-standard-2",
      "db-n1-highmem-2",
      "db-n1-highcpu-2",
      "db-n2-standard-2",
      "db-n2-highmem-2",
      "db-custom"
    ], var.gcp_sql_instance_tier)

    # Error message displayed if the provided tier is not in the valid list
    error_message = "SQL instance tier is invalid. Must be one of the following: db-f1-micro, db-g1-small, db-n1-standard-1, db-n1-standard-2, db-n1-highmem-2, db-n1-highcpu-2, db-n2-standard-2, db-n2-highmem-2, db-custom."
  }
}

variable "gcp_kubeflow_bucket_name" {
  description = "The name of the Kubeflow bucket"
  type        = string

  validation {
    condition = (
      // Ensure the bucket name is not empty
      length(var.gcp_kubeflow_bucket_name) > 0 &&

      // Validate the bucket name format:
      // - Must start with a lowercase letter
      // - Can contain lowercase letters, numbers, dashes (-), underscores (_), and dots (.)
      // - Must end with a lowercase letter or number
      can(regex("^[a-z][a-z0-9_.-]{2,61}[a-z0-9]$", var.gcp_kubeflow_bucket_name)) &&

      // Ensure the length is between 3 and 63 characters
      length(var.gcp_kubeflow_bucket_name) >= 3 && length(var.gcp_kubeflow_bucket_name) <= 63 &&

      // Ensure the bucket name does not resemble an IP address
      !can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.gcp_kubeflow_bucket_name)) &&

      // Ensure the bucket name does not contain "goog" or misspellings of "gOOgle"
      !can(regex("goog", lower(var.gcp_kubeflow_bucket_name))) &&
      !can(regex("google", lower(var.gcp_kubeflow_bucket_name)))
    )

    error_message = "Kubeflow bucket name contains invalid character(s). Valid characters are [a-z0-9-_.], except at the beginning or the end. Minimum and maximum characters allowed are 3 and 63. Bucket names must start with a lowercase letter and end with a lowercase letter or number. Must not resemble an IP address and cannot contain 'goog' or misspellings of 'gOOgle'."
  }
}



variable "gcp_mlflow_bucket_name" {
  description = "The name of the MLflow bucket"
  type        = string

  validation {
    condition = (
      // Ensure the bucket name is not empty
      length(var.gcp_mlflow_bucket_name) > 0 &&

      // Validate the bucket name format:
      // - Must start with a lowercase letter
      // - Can contain lowercase letters, numbers, dashes (-), underscores (_), and dots (.)
      // - Must end with a lowercase letter or number
      can(regex("^[a-z][a-z0-9_.-]{2,61}[a-z0-9]$", var.gcp_mlflow_bucket_name)) &&

      // Ensure the length is between 3 and 63 characters
      length(var.gcp_mlflow_bucket_name) >= 3 && length(var.gcp_mlflow_bucket_name) <= 63 &&

      // Ensure the bucket name does not resemble an IP address
      !can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.gcp_mlflow_bucket_name)) &&

      // Ensure the bucket name does not contain "goog" or misspellings of "gOOgle"
      !can(regex("goog", lower(var.gcp_mlflow_bucket_name))) &&
      !can(regex("google", lower(var.gcp_mlflow_bucket_name)))
    )

    error_message = "MLflow bucket name contains invalid character(s). Valid characters are [a-z0-9-_.], except at the beginning or the end. Minimum and maximum characters allowed are 3 and 63. Bucket names must start with a lowercase letter and end with a lowercase letter or number. Must not resemble an IP address and cannot contain 'goog' or misspellings of 'gOOgle'."
  }
}

variable "feast_redis_is_external" {
  description = "Flag to indicate if the Redis instance is external"
  type        = bool
}

variable "feast_redis_instance_name" {
  description = "The name of the Redis instance"
  type        = string

  validation {
    condition = (
      // Ensure the name is not empty
      length(var.feast_redis_instance_name) > 0 &&

      // Length between 1 and 40 characters
      length(var.feast_redis_instance_name) >= 1 && length(var.feast_redis_instance_name) <= 40 &&

      // Validate format: 
      // - Must start with a lowercase letter
      // - Can contain lowercase letters, numbers, and hyphens
      // - Must end with a lowercase letter or number
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.feast_redis_instance_name)) &&

      // Ensure no consecutive hyphens
      !can(regex("--", var.feast_redis_instance_name))
    )

    error_message = "Redis instance name contains invalid character(s). Valid characters are [a-z0-9-], except at the beginning or the end. Minimum and maximum characters allowed are 1 and 40. Consecutive hyphens are not allowed."
  }
}


variable "gcp_redis_instance_tier" {
  description = "The tier of the Redis instance"
  type        = string

  validation {
    condition = (
      // Ensure the tier is not empty
      length(var.gcp_redis_instance_tier) > 0 &&

      // Validate that the tier is one of the allowed values:
      // - "BASIC"
      // - "STANDARD_HA"
      // - "" (an empty string)
      can(regex("^(BASIC|STANDARD_HA|)$", var.gcp_redis_instance_tier))
    )
    
    error_message = "Redis instance tier is invalid. Must be either 'BASIC', 'STANDARD_HA', or an empty string, and cannot be empty."
  }
}


variable "feast_redis_instance_memory_size_gb" {
  description = "The memory size of the Redis instance in GB"
  type        = number

  validation {
    condition = var.feast_redis_instance_memory_size_gb > 0
    error_message = "Memory size of the Redis instance is invalid. Must be a positive integer greater than zero."
  }
}

variable "gke_network_name" {
  description = "The name of the GKE network"
  type        = string
  default     = "default"
}

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
