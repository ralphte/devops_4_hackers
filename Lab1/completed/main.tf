resource "digitalocean_tag" "project" {
  name = "My-First-DO"
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "Dev SSH Key"
  public_key = file("/home/vagrant/devops.pub")
}

resource "digitalocean_droplet" "devops_vm_1" {
  image = "ubuntu-20-04-x64"
  name = "devops-vm-1"
  region = "nyc1"
  size = "s-2vcpu-4gb"
  tags = [digitalocean_tag.project.id]
  private_networking = true
  ssh_keys = [
    digitalocean_ssh_key.ssh_key.fingerprint
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    agent = false
    timeout = "3m"
    private_key = file("/home/vagrant/devops")
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo adduser --disabled-password --gecos '' ansible",
      "sudo mkdir -p /home/ansible/.ssh",
      "sudo touch /home/ansible/.ssh/authorized_keys",
      "sudo echo '${file("/home/vagrant/devops.pub")}' > authorized_keys",
      "sudo mv authorized_keys /home/ansible/.ssh",
      "sudo chown -R ansible:ansible /home/ansible/.ssh",
      "sudo chmod 700 /home/ansible/.ssh",
      "sudo chmod 600 /home/ansible/.ssh/authorized_keys",
      "sudo usermod -aG sudo ansible",
      "sudo echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers"
    ]
  }
}
resource "digitalocean_firewall" "firewall" {
  name = "devops-firewall"

  droplet_ids = [digitalocean_droplet.devops_vm_1.id]
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}