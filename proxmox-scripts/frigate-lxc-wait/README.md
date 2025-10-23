# Frigate LXC Wait

## Purpose

This service is aimed to fix the smb mount timing startup errors, Instead of adding a startup delay to the container I want a more robust way to autostart the container only after the TrueNAS VM is up and running

Be sure to create the service file using and edit the ExecStart line for the path of the script

```bash
nano /etc/systemd/system/frigate-lxc-wait.service
```
