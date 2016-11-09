variable "region" {
  default = "eu-west-1"
}

variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret key"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ./terraform.pub
DESCRIPTION
  default = "~/.ssh/id_rsa.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "terraform"
}

variable "number_of_vms" {
  description = "Number of instances in deploy"
  default = "3"
}

variable "instance_type" {
  description = "AWS instance type"
  default = "t2.micro"
}

variable "aws_amis" {
  default = {
    eu-central-1 = "ami-9d09f0f2"
    eu-west-1 = "ami-45480636"
  }
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
