#!/bin/bash

echo "Don't run this script, instead set some of the env variables, then copy/paste the commands you need."
exit


export STORAGE_BUCKET="gs://your-project-name"
export EMAIL="your@email.com"

export GCP_PROJECT="your-project-name"
export GCP_v3_ZONE="europe-west4-a"
export GCP_v3_TPU_NAME="tpu-vm-3"
export GCP_v3_ACCELERATOR_TYPE="v3-8"

export GCP_v4_TPU_NAME="tpu4-vm-2"
export GCP_v4_ZONE="us-central2-b"
export GCP_v4_ACCELERATOR_TYPE="v4-8"

export GCP_v4_TPU_NAME="tpu4-vm-1"
export GCP_v4_ZONE="us-central2-b"
export GCP_v4_ACCELERATOR_TYPE="v4-32"


# >>>>> Run this part to add a disk to your TPU VM
export GCP_DISK_NAME="tpu-vm-disk-2"
export GCP_DISK_SIZE_GB=1000
export GCP_DISK_TYPE=pd-standard

# Create v3 disk
gcloud beta compute disks create $GCP_DISK_NAME \
    --project=$GCP_PROJECT \
    --type=$GCP_DISK_TYPE \
    --size="${GCP_DISK_SIZE_GB}GB" \
    --zone=$GCP_v3_ZONE

# Create v4 disk
gcloud compute disks create $GCP_DISK_NAME \
    --project=$GCP_PROJECT \
    --type=$GCP_DISK_TYPE \
    --size="${GCP_DISK_SIZE_GB}GB" \
    --zone=$GCP_v4_ZONE


# Create the TPU VM v3-8
gcloud alpha compute tpus tpu-vm create $GCP_TPU_NAME \
    --zone $GCP_v3_ZONE \
    --project $GCP_PROJECT \
    --accelerator-type v3-8 \
    --version v2-alpha \
    --data-disk source="projects/${GCP_PROJECT}/zones/${GCP_v3_ZONE}/disks/${GCP_DISK_NAME}"

# v4-32
gcloud compute tpus tpu-vm create $GCP_TPU_NAME \
  --zone $GCP_v4_ZONE \
  --project $GCP_PROJECT \
  --accelerator-type v4-32 \
  --version tpu-vm-tf-2.15.0-pod-pjrt

   \
  --data-disk source="projects/${GCP_PROJECT}/zones/${GCP_v4_ZONE}/disks/${GCP_DISK_NAME}"

# v3-8
while ! gcloud alpha compute tpus tpu-vm create $GCP_v3_TPU_NAME     --zone $GCP_v3_ZONE     --project $GCP_PROJECT     --accelerator-type $GCP_v3_ACCELERATOR_TYPE     --version tpu-ubuntu2204-base; do sleep 3 ; done

# v4_ACCELERATOR_TYPE   (v4-8 .. v4-32)
while ! gcloud compute tpus tpu-vm create $GCP_v4_TPU_NAME     --zone $GCP_v4_ZONE     --project $GCP_PROJECT     --accelerator-type $GCP_v4_ACCELERATOR_TYPE     --version tpu-ubuntu2204-base; do sleep 3 ; done

# Login to the VM v3
gcloud alpha compute tpus tpu-vm ssh $GCP_v3_TPU_NAME --zone $GCP_v3_ZONE --project $GCP_PROJECT

# Login to the VM v4
gcloud compute tpus tpu-vm ssh $GCP_v4_TPU_NAME --zone $GCP_v4_ZONE --project $GCP_PROJECT

# Create a storage bucket
gsutil mb -p ${GCP_PROJECT} -c standard -l "europe-west4" gs://${GCP_PROJECT}

# v3-8 Create a queued resource
gcloud alpha compute tpus queued-resources create  $GCP_v3_TPU_NAME --node-id $GCP_v3_TPU_NAME    --zone $GCP_v3_ZONE     --project $GCP_PROJECT     --accelerator-type $GCP_v3_ACCELERATOR_TYPE     --runtime-version tpu-ubuntu2204-base

# v4-8 or v4-32 Create a queued resource
gcloud compute tpus queued-resources create  $GCP_v4_TPU_NAME --node-id $GCP_v4_TPU_NAME    --zone $GCP_v4_ZONE     --project $GCP_PROJECT     --accelerator-type $GCP_v4_ACCELERATOR_TYPE     --runtime-version tpu-ubuntu2204-base

# v3 List queued resources
gcloud alpha compute tpus queued-resources list --project $GCP_PROJECT --zone $GCP_v3_ZONE

# v4 List queued resources
gcloud compute tpus queued-resources list --project $GCP_PROJECT --zone $GCP_v4_ZONE

# v4 Mail when created
while true; do
    TPU_STATE=$(gcloud alpha compute tpus queued-resources list --project $GCP_PROJECT --zone $GCP_v4_ZONE --format="value(state)")
    if [[ "$TPU_STATE" != "state=WAITING_FOR_RESOURCES" ]]; then
        echo -e "Subject: TPU $GCP_v4_ACCELERATOR_TYPE Assignment Notification\n\nThe TPU $GCP_v4_ACCELERATOR_TYPE has been assigned. (state=$TPU_STATE)" | msmtp "$EMAIL"
        echo "TPU $GCP_v4_ACCELERATOR_TYPE is no longer waiting. State: $TPU_STATE"
        break
    fi
    echo "TPU $GCP_v4_ACCELERATOR_TYPE is still waiting. Checking again in 60 seconds..."
    sleep 60
done


# v3 mail when created
while true; do
    TPU_STATE=$(gcloud alpha compute tpus queued-resources list --project $GCP_PROJECT --zone $GCP_v3_ZONE --format="value(state)")
    if [[ "$TPU_STATE" != "state=WAITING_FOR_RESOURCES" ]]; then
        echo -e "Subject: TPU $GCP_v3_ACCELERATOR_TYPE Assignment Notification\n\nThe TPU $GCP_v3_ACCELERATOR_TYPE has been assigned. (state=$TPU_STATE)" | msmtp "$EMAIL"
        echo "TPU $GCP_v3_ACCELERATOR_TYPE is no longer waiting. State: $TPU_STATE"
        break
    fi
    echo "TPU $GCP_v3_ACCELERATOR_TYPE is still waiting. Checking again in 60 seconds..."
    sleep 60
done