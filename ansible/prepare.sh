#!/bin/bash

export ANSIBLE_CONFIG="${2}/ansible/ansible.cfg"

# Currently it rises an error: ControlPath too long
# ssh-key must be passed via TF_VAR_private_key_path
#export ANSIBLE_SSH_ARGS="${2}/ansible/${1}-ssh.cfg"
