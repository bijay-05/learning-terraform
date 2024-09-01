This sub directory contains simple terraform script to set up development environment in azure cloud, consisting of virtual network, disks and virtual machine. The script was developed
while learning about the topic from YouTube in `freeCodeCamp`s channel.

## Key features
- Set up virtual machine along with resource group and virtual network creation for development environment.
- Post-creation, configuration is set up to breeze the step of remote-ssh VSCode into the virtual machine with `local-exec` provisioner.
- In addition to `local-exec`, `remote-exec` provisioner streamlines the installation of `Node` runtime in the virtual machine.
