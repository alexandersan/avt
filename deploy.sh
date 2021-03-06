#!/bin/bash

source_credentials () {
  case $1 in
    vagrant)
      export ANSIBLE_TARGET_GROUP="all"
    ;;
    amazon)
      export TF_VAR_access_key="$( awk -F ',' 'FNR==2{ print $2 }' $2 )"
      export TF_VAR_secret_key="$( awk -F ',' 'FNR==2{ print $3 }' $2 )"
      export AWS_ACCESS_KEY_ID="$TF_VAR_access_key"
      export AWS_SECRET_ACCESS_KEY="$TF_VAR_secret_key"
      export ANSIBLE_INVENTORY="ansible/ec2.py"
      export ANSIBLE_TARGET_GROUP="key_${TF_VAR_key_name:-'terraform'}"
    ;;
    azure)
      export TF_VAR_SUBSCRIPTION_ID="$( awk -F '=' 'FNR==2{ print $2 }' $2 )"
      export TF_VAR_CLIENT_ID="$( awk -F '=' 'FNR==3{ print $2 }' $2 )"
      export TF_VAR_CLIENT_SECRET="$( awk -F 'secret=' 'FNR==4{ print $2 }' $2 )"
      export TF_VAR_TENANT_ID="$( awk -F '=' 'FNR==5{ print $2 }' $2 )"
      export ANSIBLE_INVENTORY="ansible/azure_rm.py"
      export ANSIBLE_TARGET_GROUP="${TF_VAR_name_prefix:-'monya'}_rg"
    ;;
    google)
      echo "Not implemented yet"
      exit 1
    ;;
  esac
}

run_in () {
  cd "$DIR" && eval "$1"
}

f_help () {
  echo "$1"
  cat << EOF
For help: -h, -?, --help, help
Available environments: vagrant, amazon, azure, google
Available commands: up, ansible, status, destroy
N.B. For Amazon AWS, Azure or Google Cloud you must specify a valid credentials file.
with -c|--credentials option (for example -c ~/Downloads/credentials.csv)
EOF
  exit $2
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ANSIBLE_CONFIG="$DIR/ansible/ansible.cfg"
export ANSIBLE_STDOUT_CALLBACK=debug

# Default variables
playbook=${TF_VAR_ansible_playbook:-"ansible/deploy.yaml"}
remote_user=${TF_VAR_remote_user:-"ubuntu"}
private_key=${TF_VAR_private_key_path:-"~/.ssh/id_rsa"}

while [[ $# -gt 1 ]] #process pairs of arguments
do
key="$1"

case $key in
  vagrant|azure|amazon|google) #check for valid environment
    case $2 in
      # check for valid command
      up|ansible|destroy|status) COMMAND="$2" ;;
      *) f_help "ERROR: unsupported command" 1 ;;
    esac
    ENVIRONMENT="$key"
    shift # past argument
  ;;
  -c|--credentials)
    [ ! -f "$2" ] && f_help "ERROR: invalid credentials file" 1
    CREDENTIALS="$2"
    shift # past argument
  ;;
  *) echo "ERROR: Unknown option" && exit 1 ;;
esac
shift
done
if [ -n "$1" ]; then
  case "$1" in
    help|-h|-?|--help) f_help "deploy.sh help:" 0 ;;
    *)                 f_help "ERROR: Unknown option $@" 1 ;;
  esac
fi

source_credentials $ENVIRONMENT $CREDENTIALS

if [ "$ENVIRONMENT" == "vagrant" ]
then
  case $COMMAND in
    up) run_in "vagrant up" ;;
    status) run_in "vagrant global-status" ;;
    destroy) run_in "vagrant destroy" ;;
    ansible)
      if [ -f "$DIR/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" ]; then
        run_in "ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory -e target_group=$ANSIBLE_TARGET_GROUP $playbook"
      else
        echo "Error: No inventory file, please run 'deploy.sh vagrant up' first."
        exit 1
      fi
    ;;
  esac
else
  case $COMMAND in
    up) run_in  "terraform apply $ENVIRONMENT" ;;
    status) run_in "terraform plan $ENVIRONMENT" ;;
    destroy) run_in "terraform destroy -force $ENVIRONMENT" ;;
    ansible) run_in "ansible-playbook -v --private-key $private_key -u $remote_user -e target_group=$ANSIBLE_TARGET_GROUP $playbook" ;;
  esac
fi

