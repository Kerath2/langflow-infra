# SSH Key
resource "ibm_is_ssh_key" "ssh_key" {
  name           = "${var.prefix}-ssh-key"
  public_key     = var.ssh_public_key
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Obtener la imagen de Ubuntu
data "ibm_is_image" "os_image" {
  name = var.os_image_name
}

# Cloud-init script para instalar Podman, Postgres y Langflow
data "template_file" "user_data" {
  count    = var.vsi_count
  template = file("${path.root}/${var.cloud_init_template_path}")

  vars = {
    langflow_instances = var.langflow_instances_per_vsi
    langflow_base_port = var.langflow_base_port
    postgres_base_port = var.postgres_base_port
    vsi_name          = "${var.prefix}-vsi-${count.index + 1}"
    api_key           = var.api_key
  }
}

# Virtual Server Instances
resource "ibm_is_instance" "vsi" {
  count          = var.vsi_count
  name           = "${var.prefix}-vsi-${count.index + 1}"
  vpc            = var.vpc_id
  zone           = var.zone
  profile        = var.vsi_profile
  image          = data.ibm_is_image.os_image.id
  keys           = [ibm_is_ssh_key.ssh_key.id]
  resource_group = var.resource_group_id
  user_data      = data.template_file.user_data[count.index].rendered

  primary_network_interface {
    subnet          = var.subnet_id
    security_groups = [var.security_group_id]
  }

  boot_volume {
    name = "${var.prefix}-vsi-${count.index + 1}-boot"
  }

  tags = concat(var.tags, ["vsi-${count.index + 1}"])

  # Timeouts para evitar errores en creación
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Floating IPs para acceso público
resource "ibm_is_floating_ip" "fip" {
  count          = var.enable_floating_ips ? var.vsi_count : 0
  name           = "${var.prefix}-fip-${count.index + 1}"
  target         = ibm_is_instance.vsi[count.index].primary_network_interface[0].id
  resource_group = var.resource_group_id
  tags           = concat(var.tags, ["fip-${count.index + 1}"])
}
