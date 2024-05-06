# Define a variable for the E-commerce account id
variable "e-commerce_service_account_id" {
    type    = string
    default = "e-commerce_service_account"
}

# Define a variable for the SFTP server account id
variable "sftp_server_account_id" {
    type    = string
    default = "sftp_server_account"
}

variable "organization" {
  type = object({
    domain = string
    id     = number
  })
  default = {
    domain = "projectwork.mangini"
    id     = 590702
  }
}

variable "location" {
  type = object({
    region       = string
    multi_region = string
  })
  default = {
    region       = "europe-west1"
    multi_region = "EU"
  }
}