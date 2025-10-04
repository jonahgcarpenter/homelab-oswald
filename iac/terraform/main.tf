provider "proxmox" {
  pm_api_url = "https://pve-3.home.my-uam.com/api2/json"
}

module "talos" {
  source = "./models/talos"
}
