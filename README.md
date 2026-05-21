# Итоговый проект модуля «Облачная инфраструктура. Terraform»

### Желонкин Дмитрий

### Инструкция по выполнению итогового проекта:
Используя инструменты Docker, Docker Compose и Terraform, вам необходимо сделать следующее:

### Задание 1. Развертывание инфраструктуры в Yandex Cloud.

1. Создайте Virtual Private Cloud (VPC).
2. Создайте подсети.
3. Создайте виртуальные машины (VM):
4. Настройте группы безопасности (порты 22, 80, 443).
5. Привяжите группу безопасности к VM.
6. Опишите создание БД MySQL в Yandex Cloud.
7. Опишите создание Container Registry.
 
### Задание 2. Используя user-data (cloud-init), установите Docker и Docker Compose (см. Задания 5 модуля «Виртуализация и контейнеризация»).

### Задание 3. Опишите Docker файл (см. Задания 5 «Виртуализация и контейнеризация») c web-приложением и сохраните контейнер в Container Registry.

### Задание 4. Завяжите работу приложения в контейнере на БД в Yandex Cloud.

### Задание 5*. Положите пароли от БД в LockBox и настройте интеграцию с Terraform так, чтобы пароль для БД брался из LockBox.

---

## Описание проекта

## Terraform:

1. Создание VPC

```sh
resource "yandex_vpc_network" "web_vpc" {
  name = var.vpc_name
}
```

2. Создание подсети

Была создана подсеть в зоне А
```sh
#Create subnet in zone A
resource "yandex_vpc_subnet" "web_subnet" {
  name           = "${var.vpc_name}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.web_vpc.id
  route_table_id = yandex_vpc_route_table.rt.id
  v4_cidr_blocks = var.vm_web_default_cidr
}
```

3. Создание виртуальной машины

Получаем ID операционной системы Ubuntu
```sh
# Image OS
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}
```
Инициализируем boot disk
```sh
resource "yandex_compute_disk" "boot_disk_web" {
  image_id = var.image_id
  type     = var.boot_disk.disk.disk_type
  size     = var.boot_disk.disk.disk_size
  zone     = var.zone
}
```
Создание виртуальной машины
```sh
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
```

4. Настройте группы безопасности (порты 22, 80, 443).

Группа безопасности для беспрепятственного общения в локальной сети между ВМ
```sh
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
```
Доступ к интернету без NAT
```sh
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "route-table"
  network_id = yandex_vpc_network.web_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
```
Разрешаем HTTPS, HTTP и SSH
```sh
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
```
5. Привяжите группу безопасности к VM.

В network_interface прописываем принадлежность ВМ К Security Groups
```sh
security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_out.id]
```
6. Опишите создание БД MySQL в Yandex Cloud.

Создание кластера. Указываем характеристики кластера, версию и расположение хоста
```sh
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
```
Создаем базу данных. Указываем наш кластер и имя базы данных
```sh
resource "yandex_mdb_mysql_database" "db1" {
  cluster_id = yandex_mdb_mysql_cluster.app-mysql.id
  name       = var.mysql_database_name
}
```
Создаем пользователя базы данных и выдаем ему права
```sh
resource "yandex_mdb_mysql_user" "user1" {
  cluster_id = yandex_mdb_mysql_cluster.app-mysql.id
  name       = var.mysql_user
  password   = data.yandex_lockbox_secret_version.db_password.entries[0].text_value
  permission {
    database_name = yandex_mdb_mysql_database.db1.name
    roles         = ["ALL"]
  }
}
```
7. Опишите создание Container Registry.

Создаем Container Registry
```sh
resource "yandex_container_registry" "docker_registry" {
  name      = var.registry_name
  folder_id = var.folder_id
  labels = {
    class       = "docker"
    managed_by  = "terraform"
  }
  lifecycle {
    prevent_destroy = true
  }
}
```
Создаем в нем репозиторий
```sh
resource "yandex_container_repository" "app_docker" {
  name = "${yandex_container_registry.docker_registry.id}/${var.repository_name}"
  lifecycle {
    prevent_destroy = false
  }
}
```
Далее с помощью скрипта я собираю и отправляю image в Container Registry.
Прописал триггеры для повторного выполнения. Любое изменение файла влечет за собой пересборку и переотправку в Registry
```sh
resource "null_resource" "docker_build_and_push" {
  depends_on = [yandex_container_repository.app_docker]
  
  provisioner "local-exec" {
    command = <<-EOT
      chmod +x ../scripts/build_and_push.sh
      ../scripts/build_and_push.sh \
        "${yandex_container_registry.docker_registry.id}" \
        "${var.repository_name}"
    EOT
  }
  
  triggers = {

    dockerfile_hash = filemd5("../app/Dockerfile.python")
    script_hash = filemd5("../scripts/build_and_push.sh")
    registry_id     = yandex_container_registry.docker_registry.id
    repository_name = var.repository_name
    app_source_hash = filesha256("../app/main.py")
  }
}
```
Сам скрипт находится по пути: [Скрипт сборки и пуша в Registry](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/scripts/build_and_push.sh)

## Настройка s3 bucket with remote state + statelock

Подключение нашего терраформа к бакету.

С помощью сохраненных кредов от сервисного аккаунта и указания бэкенда мы можем сохранять state именно там, удаленно.

С помощью функци use_lockfile мы можем там же создавать lock файл, что бы избежать редактирование конфигурации из другого места.

```sh
backend "s3" {
    shared_credentials_files = [ "~/.aws/credentials" ]
    profile = "default"
    region = "ru-central1"
    bucket = "dev-tfstate"
    key    = "project-web/terraform.tfstate"
    encrypt = false

    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
```

----------
## cloud-init:

#### Задание 2. Используя user-data (cloud-init), установите Docker и Docker Compose (см. Задания 5 модуля «Виртуализация и контейнеризация»).

В cloud-init создается пользователь ubuntu с правами sudo. Отправляется ssh-ключ для подключения.

Устанавливаются пакеты:

1.  apt-transport-https
2. ca-certificates
3. curl
4. gnupg
5. lsb-release
6. unattended-upgrades

Далее устанавливается docker и docker compose. После успешного деплоя система выдает сообщение: "final_message: "The system is finally up, after (кол-во секунд) seconds""
```sh
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: false
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades
runcmd:
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ubuntu

final_message: "The system is finally up, after $UPTIME seconds"

```
---
## Dockerfile
#### Задание 3. Опишите Docker файл (см. Задания 5 «Виртуализация и контейнеризация») c web-приложением и сохраните контейнер в Container Registry.

Содержимое Dockerfile:
```Dockerfile
FROM python:3.12-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
RUN addgroup --system python && \
    adduser --system --disabled-password --ingroup python python && \
    chown python:python /app
USER python
COPY --chown=python:python --from=builder /app/venv ./venv
COPY --chown=python:python main.py .
COPY --chown=python:python root.crt .
ENV PATH="/app/venv/bin:$PATH"
CMD ["python3", "main.py"]
```

Используется multi-staging для экономии места. Данный dockerfile устанавливает зависимости, копирует нужные файлы для корреткной работы web-app
---
## Python

Данная программа собирает переменные из .env и с помощью flask и pymysql инициирует и проверяет подключения к БД
Код web-app:
```python
from flask import Flask, render_template_string
import pymysql
import os

app = Flask(__name__)

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'sadmin'),
    'password': os.environ.get('DB_PASSWORD', ''),
    'database': os.environ.get('DB_NAME', 'app'),
    'ssl_ca': os.environ.get('DB_SSL_CA', '/app/root.crt')
}

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Проверка MySQL</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .success { color: green; font-size: 24px; }
        .error { color: red; font-size: 18px; }
        button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Проверка подключения к MySQL</h1>
    <button onclick="location.reload()">Проверить</button>
    <div class="{{ 'success' if success else 'error' }}">
        <p>{{ msg }}</p>
    </div>
</body>
</html>
'''

@app.route('/')
def index():
    try:
        conn = pymysql.connect(
            host=DB_CONFIG['host'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database'],
            ssl={'ca': './root.crt'}
        )
        conn.close()
        msg = f'✅ Успешно подключено к БД {DB_CONFIG["database"]} на {DB_CONFIG["host"]}'
        success = True
    except Exception as e:
        msg = f'❌ Ошибка: {e}'
        success = False
    
    return render_template_string(HTML, msg=msg, success=success)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

requirements.txt:
```python
Flask==2.3.3
PyMySQL==1.1.0
cryptography==41.0.7
```
#### Задание 4. Завяжите работу приложения в контейнере на БД в Yandex Cloud.

Подключаем к публичному имени к БД с помощью python приложения и .env

Пример .env
```sh
DB_HOST=rc1fsda-6f084324rlkkme3sfsd1oa7.mdb.yandexcloud.net
DB_USER=someuser
DB_PASSWORD=somepassword
DB_NAME=app
DATABASE_URL=mysql://someuser:somepassword@rc1fsda-6f084324rlkkme3sfsd1oa7.mdb.yandexcloud.net/app
```

#### Задание 5*. Положите пароли от БД в LockBox и настройте интеграцию с Terraform так, чтобы пароль для БД брался из LockBox.
Инициализация пароля из LockBox
```sh
data "yandex_lockbox_secret_version" "db_password" {
  secret_id  = "e6qsue9b9pfk6khp4c01"
  version_id = "e6qkfca7ksuk1b6rld98"
}
```
![Пароль в LockBox](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/Lockbox_password_db.png)
Подставляем в .env дату полученную из ресурса выше
```sh
# Получаем host из созданного кластера
locals {
  db_host = yandex_mdb_mysql_cluster.app-mysql.host[0].fqdn
  db_user = var.mysql_user
  db_password = data.yandex_lockbox_secret_version.db_password.entries[0].text_value
  db_name = var.mysql_database_name
  
  env_content = <<-EOF
    DB_HOST=${local.db_host}
    DB_USER=${local.db_user}
    DB_PASSWORD=${local.db_password}
    DB_NAME=${local.db_name}
    DATABASE_URL=mysql://${local.db_user}:${local.db_password}@${local.db_host}/${local.db_name}
  EOF
}

resource "local_file" "env_file" {
  content  = local.env_content
  filename = "../app/.env"
}
```
---
### Ansible

Для деплоя web-app на создаваемой ВМ я использую ansible.

1. Создаем файл инвентаря

```sh
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
```

2. Пишем плейбук

Он проверяет ssh порт и далее копирует все файлы проекта, собирает image и деплоит web-app с помощью Docker-compose
```yaml
- name: Deploy web-app
  hosts: web
  vars:
    ansible_ssh_user: ubuntu
  become: true

  pre_tasks:
    - name: Validating the ssh port is open
      ansible.builtin.wait_for:
        host: "{{ (ansible_ssh_host|default(ansible_host))|default(inventory_hostname) }}"
        port: 22
        delay: 5
        timeout: 300
        state: started
        search_regex: OpenSSH
    - name: Stop unattended-upgrades before installation
      ansible.builtin.systemd:
        name: unattended-upgrades
        state: stopped

  tasks:
    - name: Copy Dockerfile
      ansible.builtin.copy:
        src: ../app/Dockerfile.python
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Copy Docker compose
      ansible.builtin.copy:
        src: ../app/docker-compose.yaml
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Copy .env
      ansible.builtin.copy:
        src: ../app/.env
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Copy main.py
      ansible.builtin.copy:
        src: ../app/main.py
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Copy root.crt
      ansible.builtin.copy:
        src: ../app/root.crt
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Copy requirements.txt
      ansible.builtin.copy:
        src: ../app/requirements.txt
        dest: /home/ubuntu
        owner: ubuntu
        group: ubuntu
        mode: '0644'
    - name: Build app image
      community.docker.docker_image_build:
        name: web-app:latest
        path: /home/ubuntu
        dockerfile: Dockerfile.python
    - name: Deploy web-app with Docker Compose
      community.docker.docker_compose_v2:
        project_name: web-app
        project_src: /home/ubuntu
        files:
          - docker-compose.yaml
        state: present
```
---
## Terraform docs

Ниже указаны все используемые ресурсы и переменные

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.3.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.14.0 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.204.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.env_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.image_info](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.inventory](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.ansible_config](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.docker_build_and_push](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_150_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [yandex_compute_disk.boot_disk_web](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_disk) | resource |
| [yandex_compute_instance.web](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance) | resource |
| [yandex_container_registry.docker_registry](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/container_registry) | resource |
| [yandex_container_repository.app_docker](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/container_repository) | resource |
| [yandex_mdb_mysql_cluster.app-mysql](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_cluster) | resource |
| [yandex_mdb_mysql_database.db1](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_database) | resource |
| [yandex_mdb_mysql_user.user1](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_user) | resource |
| [yandex_vpc_gateway.nat_gateway](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_gateway) | resource |
| [yandex_vpc_network.web_vpc](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_network) | resource |
| [yandex_vpc_route_table.rt](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table) | resource |
| [yandex_vpc_security_group.LAN](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |
| [yandex_vpc_security_group.mysql-sg](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |
| [yandex_vpc_security_group.web_out](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |
| [yandex_vpc_subnet.web_subnet](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet) | resource |
| [template_file.cloudinit](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [yandex_compute_image.ubuntu_2204_lts](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/compute_image) | data source |
| [yandex_lockbox_secret_version.db_password](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/lockbox_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boot_disk"></a> [boot\_disk](#input\_boot\_disk) | n/a | <pre>object({<br/>    disk = object({<br/>      disk_type = string<br/>      disk_size = number<br/>    })<br/>  })</pre> | <pre>{<br/>  "disk": {<br/>    "disk_size": 15,<br/>    "disk_type": "network-ssd"<br/>  }<br/>}</pre> | no |
| <a name="input_cloud_id"></a> [cloud\_id](#input\_cloud\_id) | n/a | `string` | `"b1gj4267eqa8nhcdjka9"` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | (Optional) - Yandex Cloud Folder ID where resources will be created. | `string` | `"b1gs2kftghrh9vu74phs"` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | hostname vm | `string` | `"web"` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | Boot disk image id. If not provided, it defaults to Ubuntu 22.04 LTS image id | `string` | `"fd833v6c5tb0udvk4jo6"` | no |
| <a name="input_instance_resources"></a> [instance\_resources](#input\_instance\_resources) | n/a | <pre>object({<br/>      cores = number<br/>      memory = number<br/>      core_fraction = number<br/>    })</pre> | <pre>{<br/>  "core_fraction": 20,<br/>  "cores": 2,<br/>  "memory": 2<br/>}</pre> | no |
| <a name="input_mysql_database_name"></a> [mysql\_database\_name](#input\_mysql\_database\_name) | name of first database | `string` | `"app"` | no |
| <a name="input_mysql_password"></a> [mysql\_password](#input\_mysql\_password) | Database user password | `string` | n/a | yes |
| <a name="input_mysql_user"></a> [mysql\_user](#input\_mysql\_user) | Database user | `string` | n/a | yes |
| <a name="input_nat"></a> [nat](#input\_nat) | NAT | `bool` | `true` | no |
| <a name="input_nat_mysql"></a> [nat\_mysql](#input\_nat\_mysql) | NAT for MySQL | `bool` | `true` | no |
| <a name="input_registry_name"></a> [registry\_name](#input\_registry\_name) | Docker registry name | `string` | `"webapp"` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Repository name inside registry | `string` | `"test-repository"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Variable for ssh key in cloud-init | `string` | n/a | yes |
| <a name="input_vm_web_default_cidr"></a> [vm\_web\_default\_cidr](#input\_vm\_web\_default\_cidr) | default cidr (like xxx.xxx.xxx.xxx/xx) | `list(string)` | <pre>[<br/>  "10.0.1.0/24"<br/>]</pre> | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of VPC | `string` | `"web"` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | YC Zone (A,B,C,E) | `string` | `"ru-central1-a"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_boot_disk_id"></a> [boot\_disk\_id](#output\_boot\_disk\_id) | ID of the boot disk |
| <a name="output_deployment_summary"></a> [deployment\_summary](#output\_deployment\_summary) | Summary of the deployment |
| <a name="output_mysql_cluster_id"></a> [mysql\_cluster\_id](#output\_mysql\_cluster\_id) | ID of the MySQL cluster |
| <a name="output_mysql_cluster_name"></a> [mysql\_cluster\_name](#output\_mysql\_cluster\_name) | Name of the MySQL cluster |
| <a name="output_mysql_database_name"></a> [mysql\_database\_name](#output\_mysql\_database\_name) | Name of the created database |
| <a name="output_mysql_host"></a> [mysql\_host](#output\_mysql\_host) | MySQL host FQDN |
| <a name="output_mysql_user"></a> [mysql\_user](#output\_mysql\_user) | MySQL user name |
| <a name="output_registry_id"></a> [registry\_id](#output\_registry\_id) | ID of the container registry |
| <a name="output_registry_name"></a> [registry\_name](#output\_registry\_name) | Name of the container registry |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | Name of the Docker repository |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID of the created subnet |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the created VPC network |
| <a name="output_web_app_url"></a> [web\_app\_url](#output\_web\_app\_url) | URL to access the web application |
| <a name="output_web_vm_external_ip"></a> [web\_vm\_external\_ip](#output\_web\_vm\_external\_ip) | External IP address of the web VM |
| <a name="output_web_vm_internal_ip"></a> [web\_vm\_internal\_ip](#output\_web\_vm\_internal\_ip) | Internal IP address of the web VM |
| <a name="output_web_vm_name"></a> [web\_vm\_name](#output\_web\_vm\_name) | Name of the web VM |
## Скриншоты

Обзор создаваемой виртуальной машины
![VM in YC](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/vm.png)

Сеть и подсеть
![VPC and subnets in YC](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/network.png)

Security group на внещку
![Security groups outside](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/sg.png)

S3 хранилище с state lock и с самим state
![S3](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/remotestate+lock.png)

Обзор кластера Mysql
![mysql in yc](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/mysql_overview.png)

Наше соединение mysql с программой
![connection](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/mysql_connection.png)

Проверка подключения к mysql (web приложение)
![Пароль в LockBox](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/web-app_working.png)

Проверка работующего контейнера
![docker ps](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/img/docker_ps.png)


---
## Ссылки

[Проект Terraform](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/terraform)

[Проект Ansible](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/ansible)

[Web приложение + docker](https://github.com/deadwhitepunk/hw-terr-result-project/blob/main/app)