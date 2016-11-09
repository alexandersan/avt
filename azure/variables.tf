variable "region" {
  default = "West US"
}

variable "geo_region" {
  default = "westus"
}

variable "storage_type" {
  default = "Standard_LRS"
}

variable "SUBSCRIPTION_ID" {
  description = "Azure subscription id"
}

variable "CLIENT_SECRET" {
  description = "Azure secret key"
}

variable "CLIENT_ID" {
  description = "Azure access id"
}

variable "TENANT_ID" {
  description = "Azure tenant id"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "number_of_vms" {
  description = "Number of instances in deploy"
  default = "1"
}

variable "instance_type" {
  description = "Azure instance type"
  default = "Standard_A1"
}

variable "os_type" {
  default = "16.04.0-LTS"
}

variable "ansible_playbook" {
  description = "Relative path to Ansible playbook"
  default = "ansible/deploy.yaml"
}

variable "remote_user" {
  description = "User allowed to provision instances with Ansible"
  default = "ubuntu"
}

variable "private_key_path" {
  description = "path to private key"
  default = "~/.ssh/id_rsa"
}
