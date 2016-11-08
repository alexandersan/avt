# avt
Ansible + Vagrant + Terraform

This is  an alternative deploy mechanism version
it assumes that you already have installed and correctly
configured:
  - Ansible (>= 2.2)
  - Vagrant (>= 1.7.6) for local deploy
  - Terraform (>= 0.7.1) for remote deploy

Despite the ability of Vagrant and Terraform to work on
MS Windows machine you have to use Linux for control machine.
[For additional info please read](http://docs.ansible.com/ansible/intro_windows.html#reminder-you-must-have-a-linux-control-machine)

# Configurable environment variables

Works with both Vagrant and Terraform:
```bash
TF_VAR_number_of_vms
TF_VAR_ansible_playbook
```
Works with current Terraform AWS:
```bash
TF_VAR_region
TF_VAR_access_key
TF_VAR_secret_key
TF_VAR_key_name
TF_VAR_instance_type
TF_VAR_aws_amis
TF_VAR_remote_user
TF_VAR_private_key_path
TF_VAR_public_key_path
```
