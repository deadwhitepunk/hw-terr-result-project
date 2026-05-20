resource "yandex_mdb_mysql_cluster" "app-mysql" {
  access {
    web_sql = true
  }
  name                = "mysql-${var.zone}"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.web_vpc.id
  version             = "8.0"
  security_group_ids  = [ yandex_vpc_security_group.mysql-sg.id ]
  

  resources {
    disk_size          = 10
    disk_type_id       = "network-hdd"
    resource_preset_id = "b1.medium"
  }

  host {
    zone             = var.zone
    subnet_id        = yandex_vpc_subnet.web_subnet.id
    assign_public_ip = var.nat_mysql
  }
}

resource "yandex_mdb_mysql_database" "db1" {
  cluster_id = yandex_mdb_mysql_cluster.app-mysql.id
  name       = var.mysql_database_name
}

resource "yandex_mdb_mysql_user" "user1" {
  cluster_id = yandex_mdb_mysql_cluster.app-mysql.id
  name       = var.mysql_user
  password   = data.yandex_lockbox_secret_version.db_password.entries[0].text_value
  permission {
    database_name = yandex_mdb_mysql_database.db1.name
    roles         = ["ALL"]
  }
}
