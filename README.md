# Project Oswald (aka Homelab)

<p align="center">
  <img alt="Server Rack" src="./pictures/rack.jpeg" width="60%">
</p>

---

<p align="left">
  <img src="https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white" alt="Proxmox"/>
  <img src="https://img.shields.io/badge/Talos-525ddc?style=for-the-badge&logo=talos&logoColor=white" alt="Talos"/>
  <img src="https://img.shields.io/badge/Pi--hole-96060C?style=for-the-badge&logo=pi-hole&logoColor=white" alt="Pi-hole"/>
  <img src="https://img.shields.io/badge/Home Assistant-41BDF5?style=for-the-badge&logo=homeassistant&logoColor=white" alt="Home Assistant"/>
  <img src="https://img.shields.io/badge/TrueNAS-0095D5?style=for-the-badge&logo=truenas&logoColor=white" alt="TrueNAS"/>
  <img src="https://img.shields.io/badge/UniFi-0193D7?style=for-the-badge&logo=ubiquiti&logoColor=white" alt="UniFi"/>
  <img src="https://img.shields.io/badge/Portainer-13BEF9?style=for-the-badge&logo=portainer&logoColor=white" alt="Portainer"/>
  <img src="https://img.shields.io/badge/Minecraft-59A653?style=for-the-badge&logoColor=white" alt="Minecraft"/>
  <img src="https://img.shields.io/badge/Ollama-000000?style=for-the-badge&logo=ollama&logoColor=white" alt="Ollama"/>
  <img src="https://img.shields.io/badge/Longhorn-4A154B?style=for-the-badge&logoColor=white" alt="Longhorn"/>
  <img src="https://img.shields.io/badge/Nginx Proxy Manager-F15833?style=for-the-badge&logo=nginx&logoColor=white" alt="Nginx Proxy Manager"/>
  <img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white" alt="Grafana"/>
  <img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" alt="Prometheus"/>
  <img src="https://img.shields.io/badge/Vaultwarden-175DDC?style=for-the-badge&logo=vaultwarden&logoColor=white" alt="Vaultwarden"/>
  <img src="https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white" alt="Traefik"/>
  <img src="https://img.shields.io/badge/Flux--CD-44A1C3?style=for-the-badge&logo=flux&logoColor=white" alt="FluxCD"/>
  <img src="https://img.shields.io/badge/Frigate-000000?style=for-the-badge&logo=frigate&logoColor=white" alt="Frigate"/>
  <img src="https://img.shields.io/badge/Cert--Manager-175DDC?style=for-the-badge&logoColor=white" alt="Cert-Manager"/>
  <img src="https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/>
  <img src="https://img.shields.io/badge/Sealed Secrets-0D3ECC?style=for-the-badge&logoColor=white" alt="Sealed Secrets"/>
  <img src="https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white" alt="WireGuard"/>
</p>

---

## Todo

### [Add List](https://github.com/stars/jonahgcarpenter/lists/homelab-todo)

### Problems:

- alert manager setup
- fix WoLAN
- check that NUT client works for shutdown
- rename pve-3 -> pve-0
- split GPU between multiple LXCs instead of using passthrough
- properly pass drives through to TrueNAS vm for smart values
- track helm chart versions with flux automations

## Hardware

### [2x U7 Lite](https://store.ui.com/us/en/category/all-wifi/products/u7-lite)

### [UDM-SE](https://store.ui.com/us/en/category/all-cloud-gateways/products/udm-se)

- 2 GbE PoE+
- 6 GbE PoE
- 2.5 GbE WAN
- 2 10G SFP+

### [Switch Pro Max 24 PoE](https://store.ui.com/us/en/category/switching-professional-max-xg/products/usw-pro-max-24-poe?variant=usw-pro-max-24-poe)

- 8 GbE PoE+
- 8 GbE PoE++
- 8 2.5 GbE PoE++
- 2 10G SFP+

### [Talos Cluster](https://www.gmktec.com/products/amd-ryzen-7-5825u-mini-pc-nucbox-m5-plus?srsltid=AfmBOorNrOPnRo3cqmPHBq14s82hdWG4dPwe6ntEimRl0J_gWKyXjpC3)

- Ryzen 7 5825U 8C/16T 4.5GHz
- 2x8GB 3200MHz DDR4
- 500GB NVMe
- Dual 2.5GB RJ45

### [PVE 0](https://pcpartpicker.com/user/HeyItsJonah/saved/bkgVD3)

- Ryzen 5 3600 6C/12T 3.6GHz
- 4x16GB 3200MHz DDR4
- 500GB NVMe
- 2x2TB 3.5" Drive
- RTX 3060 8GB VRAM
- Coral TPU USB

### [Home Assistant](https://www.home-assistant.io/yellow/)

- Compute Module 4
- 4GB Ram

### [Tripplite UPS](https://a.co/d/gjzwQbd)

- 1500VA
- 1440W
