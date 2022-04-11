#!/bin/bash

# latest release example
wget $(wget -q -nv -O- https://api.github.com/repos/aquasecurity/tfsec/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("linux-amd64")) | .browser_download_url') -nv -O ./tfsec && chmod +x ./tfsec

# specific release example
wget $(wget -q -nv -O- https://api.github.com/repos/google/go-containerregistry/releases 2>/dev/null | jq '.[] | select(.name=="${crane_version}")'|jq -r '.assets[]|select(.browser_download_url | contains("Linux_x86"))|.browser_download_url') -nv -O ./crane.tar.gz
      