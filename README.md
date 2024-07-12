* `youruser` : username you have on the tpu-vms
* `your-project-name` : the Google project name you have on the tpu-vms
* `myprojectdir` : the project directory you have on the tpu-vms

Inspect `setup_tpu_vm.sh`, set env variables for the kind of tpu-vm to create or request with a queued resource, and then run either the create or queued resource command. It also contains a one-liner to send you an email when the tpu-vm is ready.

Installing software:

`install_t3_vm.sh` is a script to install software on a tpu-v3-vm
`install_t4_vm.sh` is a script to install software on a tpu-v4-vm
