resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg-${var.hostname}"
  network_id = yandex_vpc_network.web_vpc.id
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

}

resource "yandex_vpc_security_group" "web_out" {
  name       = "web-sg-${var.hostname}"
  network_id = yandex_vpc_network.web_vpc.id


  ingress {
    description    = "Allow HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "Allow SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "mysql-sg" {
  name       = "mysql-sg"
  network_id = yandex_vpc_network.web_vpc.id

  ingress {
    description    = "MySQL®"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}