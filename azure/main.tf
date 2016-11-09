provider "azurerm" {
  subscription_id = "${var.SUBSCRIPTION_ID}"
  client_id       = "${var.CLIENT_ID}"
  client_secret   = "${var.CLIENT_SECRET}"
  tenant_id       = "${var.TENANT_ID}"
}

resource "azurerm_resource_group" "monya" {
    name = "monya_rg"
    location = "${var.region}"
}

resource "azurerm_virtual_network" "network" {
    name = "monya_net"
    address_space = ["10.2.0.0/16"]
    location = "${var.region}"
    resource_group_name = "${azurerm_resource_group.monya.name}"
}

resource "azurerm_subnet" "subnet" {
    name = "monyasubnet"
    resource_group_name = "${azurerm_resource_group.monya.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "10.2.2.0/24"
}

resource "azurerm_storage_account" "storage" {
    name = "monyastorage"
    resource_group_name = "${azurerm_resource_group.monya.name}"
    location = "${var.geo_region}"
    account_type = "${var.storage_type}"
}

resource "random_id" "password" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    admin_username = "${var.remote_user}"
  }
  byte_length = 8
}

resource "azurerm_public_ip" "pubip" {
    name = "publicip"
    location = "${var.region}"
    resource_group_name = "${azurerm_resource_group.monya.name}"
    public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "iface" {
    name = "iface"
    location = "${var.region}"
    resource_group_name = "${azurerm_resource_group.monya.name}"

    ip_configuration {
        name = "netconfiguration1"
        subnet_id = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.pubip.id}"
    }
}

resource "azurerm_storage_container" "container" {
    name = "monyavhds"
    resource_group_name = "${azurerm_resource_group.monya.name}"
    storage_account_name = "${azurerm_storage_account.storage.name}"
    container_access_type = "private"
}

resource "azurerm_virtual_machine" "node" {
    count = "${var.number_of_vms}"
    name = "${format("node-%03d", count.index )}"
    location = "${var.region}"
    resource_group_name = "${azurerm_resource_group.monya.name}"
    network_interface_ids = ["${azurerm_network_interface.iface.id}"]
    vm_size = "${var.instance_type}"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "${var.os_type}"
        version = "latest"
    }

    storage_os_disk {
        name = "${format("osdrive-%03d", count.index )}"
        vhd_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.container.name}/${format("osdrive-%03d", count.index)}.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "${format("node-%03d", count.index )}"
        admin_username = "${random_id.password.keepers.admin_username}"
        admin_password = "${random_id.password.hex}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path = "/home/${var.remote_user}/.ssh/authorized_keys"
            key_data = "${file("${var.public_key_path}")}"
        }
    }

    tags {
        environment = "test"
    }
}

resource "null_resource" "cluster" {
  triggers {
    node_instance_ids = "${join(",", azurerm_virtual_machine.node.*.id)}"
  }

  provisioner "local-exec" {
      command = "ansible-playbook -v --private-key=\"${var.private_key_path}\" -u ${var.remote_user} -i \"${azurerm_public_ip.pubip.ip_address},\" ${path.root}/../${var.ansible_playbook}"
  }
}
