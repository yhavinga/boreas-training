#git submodule init
#git submodule update

pushd EasyDeL
pip install -e .
popd
pushd FJFormer
pip install -e .
popd


# Upgrade JAX to 0.4.29 if the current version is below 0.4.29
version_lt() {
  # Return true if $1 is less than $2
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}
current_version=$(pip show jax | grep Version | awk '{print $2}')
target_version="0.4.29"
BLINK_TURQUOISE='\033[5;36m'
RESET='\033[0m'
if version_lt "$current_version" "$target_version"; then
  echo -e "${BLINK_TURQUOISE}Current version ($current_version) is below $target_version. Installing JAX $target_version...${RESET}"
  pip install jax[tpu]==0.4.29 -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
else
  echo -e "${BLINK_TURQUOISE}Current version ($current_version) is $target_version or above. No installation needed.${RESET}"
fi
