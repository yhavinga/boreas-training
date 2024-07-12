sudo umount /mnt/ramdisk || echo not_mounted
# if the ramdisk is not already mounted, mount it
if ! mount | grep -Fq "/mnt/ramdisk"; then
  sudo mkdir /mnt/ramdisk || echo exists
  sudo mount -t tmpfs -o size=175g tmpfs /mnt/ramdisk
  sudo chown youruser.youruser /mnt/ramdisk
fi

mkdir /mnt/ramdisk/hub
mkdir -p /home/youruser/.cache/huggingface
ln -s /mnt/ramdisk/hub /home/youruser/.cache/huggingface/hub

export HF_DATASETS_CACHE=/mnt/ramdisk
