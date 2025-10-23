provider "proxmox" {
  pm_api_url = "https://pve-3.home.jonahsserver.com/api2/json"
}

module "talos" {
  source = "./modules/talos"
}
