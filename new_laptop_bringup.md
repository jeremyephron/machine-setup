System76, Ubuntu 20.04

- `sudo apt update && sudo apt-get update`
- `sudo apt full-upgrade -y --fix-missing`
- `sudo apt install tlp`


## Setup Script

```bash
PLATFORM=`uname`
if [[ "$PLATFORM" == "Linux" ]]; then
  sudo apt update \
    && sudo apt-get update \
    && sudo apt full-upgrade -y --fix-missing \
    && sudo apt install -y tlp
    && sudo tlp start
elif [[ "$PLATFORM" == "Darwin" ]]; then
  # mac stuff
fi
```
