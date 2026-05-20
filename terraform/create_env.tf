# Получаем host из созданного кластера
locals {
  db_host = yandex_mdb_mysql_cluster.app-mysql.host[0].fqdn
  db_user = var.mysql_user
  db_password = data.yandex_lockbox_secret_version.db_password.entries[0].text_value
  db_name = var.mysql_database_name
  
  # Содержимое .env файла
  env_content = <<-EOF
    DB_HOST=${local.db_host}
    DB_USER=${local.db_user}
    DB_PASSWORD=${local.db_password}
    DB_NAME=${local.db_name}
    DATABASE_URL=mysql://${local.db_user}:${local.db_password}@${local.db_host}/${local.db_name}
  EOF
}

# Создаем файл .env
resource "local_file" "env_file" {
  content  = local.env_content
  filename = "../app/.env"
}