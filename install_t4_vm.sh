#!/bin/bash

export STORAGE_BUCKET="gs://your--project-name"

export GCP_PROJECT="your--project-name"
export GCP_ZONE_v3="europe-west4-a"
export GCP_ZONE_v4="us-central2-b"
export GCP_TPU_NAME="tpu4-vm-1"
#export GCP_TPU_NAME="tpu4-vm-2"
#export GCP_TPU_NAME="tpu4-vm-3"

# >>>>> Run this part to add a disk to your TPU VM
export GCP_DISK_NAME="tpu-vm-disk-2"
export GCP_DISK_SIZE_GB=1000
export GCP_DISK_TYPE=pd-standard



function upload_workdir() {
  pushd "$(git rev-parse --show-toplevel)/.." || exit
  zip -r myprojectdir.zip myprojectdir -x "*venv/*" "*EasyDel-Checkpoints*" "*arrow" "*__pycache__*" "*.easy" "*.git*" "*.zst*" "*.idea*" "*.ipynb_checkpoints"
  gcloud compute tpus tpu-vm scp myprojectdir.zip $GCP_TPU_NAME: \
    --worker=all \
    --zone=$GCP_ZONE_v4
  rm myprojectdir.zip
  gcloud compute tpus tpu-vm ssh $GCP_TPU_NAME \
    --zone $GCP_ZONE_v3 \
    --project $GCP_PROJECT \
    --worker all \
    --command "rm -rf EasyDeL FJFormer"
  # now extract
  gcloud compute tpus tpu-vm ssh $GCP_TPU_NAME \
    --zone $GCP_ZONE_v4 \
    --project $GCP_PROJECT \
    --worker all \
    --command "unzip -o myprojectdir.zip"
  popd || exit
}

function run_install_script() {
  # the script is passed as argument
  gcloud compute tpus tpu-vm ssh $GCP_TPU_NAME \
    --zone $GCP_ZONE_v4 \
    --project $GCP_PROJECT \
    --worker all \
    --command "cd myprojectdir && [[ -d venv/bin ]] && source venv/bin/activate; bash -x ./${1}"
}

function run_command() {
  # the command is passed as argument
  gcloud compute tpus tpu-vm ssh $GCP_TPU_NAME \
    --zone $GCP_ZONE_v4 \
    --project $GCP_PROJECT \
    --worker all \
    --command "if [[ -d myprojectdir ]]; then cd myprojectdir && [[ -d venv/bin ]] && source venv/bin/activate; fi; export PYTHONPATH=/home/yeb/myprojectdir ; export HF_DATASETS_CACHE=/mnt/ramdisk; ${1}"
}

function copy_file() {
  SRC=$1
  DST=$2
  gcloud compute tpus tpu-vm scp "${SRC}" "${GCP_TPU_NAME}:${2}" \
    --worker=all \
    --zone=$GCP_ZONE_v4
}


run_command "rm -rf ~/myprojectdir"
upload_workdir
run_install_script "install_1_python3_go_venv.sh"
run_install_script "install_2_jax_torch.sh"
run_install_script "install_3_submodule.sh"

#####run_command "rm -rf ~/.cache/huggingface"
run_command "mkdir -p ~/.cache/huggingface"
copy_file ~/.cache/huggingface/token .cache/huggingface
copy_file ~/.netrc .netrc
copy_file "install_5_hfcache_ramdisk.sh" "myprojectdir/"
run_command "git config --global credential.helper store"
##
run_install_script "install_5_hfcache_ramdisk.sh"

#copy_file "dataset/*.py" "myprojectdir/dataset/"
#copy_file 'run/2024*.py' "myprojectdir/run/"

#run_command "python tools/jax_devices.py"
#run_command "pip install jax[tpu]==0.4.23 -f https://storage.googleapis.com/jax-releases/libtpu_releases.html"
#run_command "python run/20240328_mistral_lion_new3_pretrain_v432vm1-werktniet.py"
#run_command "python run/20240329_mistral_lion_new5_pretrain_v432vm1.py"
run_command "df -h"