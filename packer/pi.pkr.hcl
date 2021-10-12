variable "wifi_name" {
  type = string
}

variable "wifi_password" {
  type = string
  sensitive = true
}

variable "ssh_key_location" {
  type = string
}

variable "user_name" {
  type = string
}

variable "user_password" {
  type = string
  sensitive = true
}

variable "dns_server_primary" {
  type = string
}

variable "dns_server_secondary" {
  type = string
}

variable "hostname" {
  type = string
}

variable "ip_address" {
  type = string
}

variable "netmask" {
  type = string
}


source "arm-image" "raspberry-pi-os-lite" {
  /*
    Release date: May 7th 2021
    Kernel version: 5.10
    Size: 444MB
  */
  iso_url = "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip"
  iso_checksum = "sha256:c5dad159a2775c687e9281b1a0e586f7471690ae28f2f2282c90e7d59f64273c"
  last_partition_extra_size = 1 * 1024 * 1024 * 1024 # 1GB
}

build {
  name    = "setup-raspberry-pi"
  sources = [
    "source.arm-image.raspberry-pi-os-lite"
  ]

  # Enable SSH
  provisioner "shell" {
    inline = [
      "touch /boot/ssh"
    ]
  }

  # Set WiFi Details
  provisioner "file" {
    content = templatefile("${path.root}/templates/wpa_supplicant.conf", {
      ssid = var.wifi_name
      password = var.wifi_password
    })
    destination = "/etc/wpa_supplicant/wpa_supplicant.conf"
  }

  # Set hostname
  provisioner "file" {
    content = var.hostname
    destination = "/etc/hostname"
  }

  provisioner "file" {
    content = templatefile(
      "${path.root}/templates/hosts",
      { hostname = var.hostname }
    )
    destination = "/etc/hosts"
  }

  # Set DHCP settings
  provisioner "file" {
    content = templatefile(
      "${path.root}/templates/dhcpcd.conf",
      {
        ip_address = "${var.ip_address}/${var.netmask}"
        dns_servers = [
          var.dns_server_primary,
          var.dns_server_secondary
        ]
      }
    )
    destination = "/etc/dhcpcd.conf"
  }

  # Add SSH key to authorized_keys
  provisioner "file" {
    source = var.ssh_key_location
    destination = "/home/pi/.ssh/authorized_keys"
  }

  # Disable password authentication for ssh
  provisioner "shell" {
    inline = [
      "sed '/PasswordAuthentication/d' -i /etc/ssh/sshd_config",
      "echo  >> /etc/ssh/sshd_config",
      "echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config"
    ]
  }

  # Don't start GUI
  provisioner "shell" {
    inline = [
      "systemctl set-default multi-user.target"
    ]
  }

  # /etc/systemd/system/pigpiod.service.d/public.conf
  provisioner "file" {
    source = "templates/pigpiod.conf"
    destination = "/etc/systemd/system/pigpiod.service.d/public.conf"
  }

  # Replace pi with a new user and set their password
  provisioner "shell" {
    inline = [
      "useradd -m -G sudo -s /bin/bash ${var.user_name}",
      "echo ${var.user_password} | sudo passwd ${var.user_name}",
      "echo ${var.user_name} ALL=NOPASSWD:ALL >> /etc/sudoers", # TODO could I use a group instead?
      "userdel pi"
    ]
  }

  # Set firmware settings using config.txt template (config.txt replaces bios on raspberry pi)
  provisioner "file" {
    source = "templates/config.txt"
    destination = "/boot/config.txt"
  }
}

packer {
  # required_plugins {
  #   arm-image = "1.2.0"
  # }
}