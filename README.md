# Postinstall-network-configuration
Script for post-installation blind network configuration

1. Install Windows OS from template.
2. Mount C: partition in rescue image and upload ifcfg.ps1 in root of C:\ partition.
3. Replace MAC variable in ifcfg.ps1 with correct MAC.
4. Boot Windows OS into qemu 
5. Run PowerShell and run C:\ifcfg.ps1 -task
6. Shutdown qemu and reboot into OS

For debug, you can find ifcfg_{date}.log in root of C:\ partition
