#!/bin/bash

source_credentials () {
  case $1 in
    vagrant) return ;;
    amazon)
      export TF_VAR_access_key="$( awk -F ',' 'FNR==2{ print $2 }' $2 )"
      export TF_VAR_secret_key="$( awk -F ',' 'FNR==2{ print $3 }' $2 )"
      export AWS_ACCESS_KEY_ID="$TF_VAR_access_key"
      export AWS_SECRET_ACCESS_KEY="$TF_VAR_secret_key"
    ;;
    azure) source $2 ;;
    google)
      echo "Not implemented yet"
      exit 1
    ;;
  esac
}

run_in () {
  cd "$DIR" && eval "$1"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

key_name=${TF_VAR_key_name:-"terraform"}

# Default variables

playbook=${TF_VAR_ansible_playbook:-"ansible/deploy.yaml"}
remote_user=${TF_VAR_remote_user:-"ubuntu"}
private_key=${TF_VAR_private_key_path:-"~/.ssh/terraform"}

while [[ $# -gt 1 ]] #process pairs of arguments
do
key="$1"

case $key in
  help|-h|-?|--help)
    cat << EOF
Available environments: vagrant, amazon, azure, google
Available commands: up, ansible, status, destroy
N.B. For Amazon AWS, Azure or Google Cloud you must specify a valid credentials file.
with -c|--credentials option (for example -c ~/Downloads/credentials.csv)
EOF
  ;;
  vagrant|azure|amazon|google) #check for valid environment
    case $2 in
      # check for valid command
      up|ansible|destroy|status) COMMAND="$2" ;;
      *) echo "ERROR: unsupported command" && exit 1 ;;
    esac
    ENVIRONMENT="$key"
    shift # past argument
  ;;
  -c|--credentials)
    [ ! -f "$2" ] && echo "ERROR: invalid credentials file" && exit 1
    CREDENTIALS="$2"
    shift # past argument
  ;;
  *) echo "ERROR: Unknown option" && exit 1 ;;
esac
shift
done
if [ -n "$1" ]; then
  cat << EOF
ERROR: Unknown option $@
Available environments: vagrant, amazon, google
Available commands: up, ansible, status, destroy
N.B. For Amazon AWS or Google Cloud you must specify a valid vredentials file.
with -c|--credentials option (for example -c ~/Downloads/credentials.csv)
EOF
  exit 1
fi

source "$DIR"/ansible/prepare.sh $ENVIRONMENT $DIR
source_credentials $ENVIRONMENT $CREDENTIALS

if [ "$ENVIRONMENT" == "vagrant" ]
then
  case $COMMAND in
    up) run_in "vagrant up" ;;
    status) run_in "vagrant global-status" ;;
    destroy) run_in "vagrant destroy" ;;
    ansible)
      if [ -f "$DIR/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" ]; then
        run_in "ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory $playbook"
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
    ansible) run_in "ansible-playbook --private-key $private_key -u $remote_user -i ansible/ec2.py -e target_group=$key_name $playbook" ;;
  esac
fi

