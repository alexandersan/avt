# -*- mode: ruby -*-
# vi: set ft=ruby :
# Include some custom functions
require './vagrant/vagrantfile-additions.rb'

# Install necessary plugins
install_plugins %w[ vagrant-libvirt ]
# Check environment configuration
vms = ENV['TF_VAR_number_of_vms'] || '1'
playbook = ENV['TF_VAR_ansible_playbook'] || 'ansible/deploy.yaml'
# Set default "unfare" resource limits for VM
resources = { "mem" => "1024", "cpus" => "1" }

Vagrant.configure("2") do |config|
  # Call fair resorse allocator
  # resources = os_check(vms.to_i)

  vms.to_i.times do |i|
    config.vm.define "node-#{i}" do |config|
      config.vm.box = "sylvainjoyeux/ubuntu-16.04-x86_64"

      setup_guest_vm(config)

      config.vm.provider "libvirt" do |vl|
        vl.memory = "#{resources['mem']}"
        vl.cpus = "#{resources['cpus']}"
      end

      config.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--memory", "#{resources['mem']}", "--cpus", "#{resources['cpus']}"]
      end

      fix_tty_error(config)

      config.vm.hostname = "node-#{i}"

      if i == vms.to_i - 1
        config.vm.provision "ansible" do |ansible|
          ansible.limit = "all"
          ansible.playbook = "#{playbook}"
        end
      end
    end
  end

end
