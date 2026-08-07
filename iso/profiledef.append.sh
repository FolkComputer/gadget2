# --- Folk tabletop overrides, appended to releng's profiledef.sh by build.sh ---
iso_name="folk-archlinux"
iso_label="FOLK_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Folk Computer <https://folk.computer>"
iso_application="Folk tabletop live environment"
file_permissions+=(
  ["/usr/local/bin/folk-init"]="0:0:755"
  ["/usr/local/bin/folk-start"]="0:0:755"
  ["/usr/local/bin/folk-install-to-disk"]="0:0:755"
  ["/etc/sudoers.d/folk"]="0:0:440"
)
