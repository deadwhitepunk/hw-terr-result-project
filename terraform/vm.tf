resource "yandex_vpc_network" "web_vpc" {
  name = var.vpc_name
}

#Create subnet in zone A
resource "yandex_vpc_subnet" "web_subnet" {
  name           = "${var.vpc_name}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.web_vpc.id
  route_table_id = yandex_vpc_route_table.rt.id
  v4_cidr_blocks = var.vm_web_default_cidr
}

# Image OS
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

#Disk for VM web
resource "yandex_compute_disk" "boot_disk_web" {
  image_id = var.image_id
  type     = var.boot_disk.disk.disk_type
  size     = var.boot_disk.disk.disk_size
  zone     = var.zone
}

#Create VM web
resource "yandex_compute_instance" "web" {
  name        = "${var.zone}-${var.hostname}"
  hostname    = var.hostname
  zone        = var.zone

  resources {
    cores         = var.instance_resources.cores
    memory        = var.instance_resources.memory
    core_fraction = var.instance_resources.core_fraction
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk_web.id
  }

  scheduling_policy { preemptible = true }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.web_subnet.id
    nat                = var.nat
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_out.id]
  }
}

data "template_file" "cloudinit" {
  template = file("./cloud-init.yml")

  vars = {
    ssh_public_key = file("~/.ssh/id_ed25519.pub")
  }
}

resource "time_sleep" "wait_150_seconds" {
  create_duration = "150s"
}

# Fill ansible inventory
resource "local_file" "inventory" {
  content  = <<-XYZ
[web]
${yandex_compute_instance.web.network_interface.0.nat_ip_address}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3

ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
XYZ
  filename = "../ansible/inventory.ini"
}

 resource "null_resource" "ansible_config" {
   depends_on = [
     yandex_compute_instance.web,
     local_file.env_file,
     local_file.inventory,
     time_sleep.wait_150_seconds
   ]
   provisioner "local-exec" {
     command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../ansible/inventory.ini ../ansible/playbook.yml"
   }
 }