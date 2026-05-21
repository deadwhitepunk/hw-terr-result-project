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
