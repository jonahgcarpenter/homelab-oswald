#!/bin/bash

# Frigate Recording Archive
# Moves complete YYYY-MM-DD recording directories from one offline backup disk
# onto two destination disks, removing source files after successful transfers.
# Usage: sudo /path/to/clone_disk.sh <source> <destination_1> <destination_2>
# Example: sudo /root/clone_disk.sh /dev/sdb1 /dev/sdd1 /dev/sde1

set -u
set -o pipefail
export LC_ALL=C

# Configuration
SOURCE_MNT="/mnt/frigate_backups"
DEST1_MNT="/mnt/frigate_usb_1"
DEST2_MNT="/mnt/frigate_usb_2"
RECORDINGS_DIR="recordings"
SAFETY_MARGIN_BYTES=$((10 * 1024 * 1024 * 1024))
MIN_DATE_OVERHEAD_BYTES=$((64 * 1024 * 1024))
EMAIL_RECIPIENT="email@gmail.com"
LOG_FILE="/var/log/clone_disk.log"

SOURCE_MOUNTED=0
DEST1_MOUNTED=0
DEST2_MOUNTED=0
SOURCE_BYTES_BEFORE="unknown"
SOURCE_BYTES_AFTER="unknown"
DEST1_BYTES_MOVED=0
DEST2_BYTES_MOVED=0
DEST1_DAYS_MOVED=0
DEST2_DAYS_MOVED=0
CAPACITY_EXHAUSTED=0
RESULT_DETAIL="Transfer did not start."

usage() {
  echo "Usage: $0 <source_partition> <destination_partition_1> <destination_partition_2>"
  echo "Example: $0 /dev/sdb1 /dev/sdd1 /dev/sde1"
}

get_tree_size() {
  local path="$1"
  local size
  local unused

  if ! read -r size unused < <(du -s -B1 --apparent-size -- "$path"); then
    return 1
  fi

  if [[ ! "$size" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  printf '%s\n' "$size"
}

get_available_bytes() {
  local path="$1"
  local -a output=()
  local available

  if ! mapfile -t output < <(df -B1 --output=avail -- "$path"); then
    return 1
  fi

  if (( ${#output[@]} < 2 )); then
    return 1
  fi

  available="${output[1]//[[:space:]]/}"
  if [[ ! "$available" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  printf '%s\n' "$available"
}

verify_mount() {
  local path="$1"
  local expected_device="$2"
  local mounted_device
  local canonical_device

  if ! mounted_device=$(findmnt -rn -T "$path" -o SOURCE); then
    return 1
  fi
  if ! canonical_device=$(readlink -f -- "$mounted_device"); then
    return 1
  fi

  [[ "$canonical_device" == "$expected_device" ]]
}

finalize() {
  local status=$?
  local subject
  local body

  trap - EXIT INT TERM

  echo "---"
  echo "Running cleanup..."

  if (( DEST2_MOUNTED )); then
    if umount "$DEST2_MNT"; then
      echo "Unmounted $DEST2_MNT."
    else
      echo "Error: Failed to unmount $DEST2_MNT." >&2
      status=1
    fi
  fi

  if (( DEST1_MOUNTED )); then
    if umount "$DEST1_MNT"; then
      echo "Unmounted $DEST1_MNT."
    else
      echo "Error: Failed to unmount $DEST1_MNT." >&2
      status=1
    fi
  fi

  if (( SOURCE_MOUNTED )); then
    if umount "$SOURCE_MNT"; then
      echo "Unmounted $SOURCE_MNT."
    else
      echo "Error: Failed to unmount $SOURCE_MNT." >&2
      status=1
    fi
  fi

  if (( status == 0 )); then
    subject="Success: Frigate recording archive complete"
  else
    subject="Error: Frigate recording archive failed"
  fi

  printf -v body '%s\n\nSource bytes before: %s\nSource bytes after: %s\nDestination 1: %d dates, %d bytes\nDestination 2: %d dates, %d bytes\nCapacity exhausted: %s\nExit status: %d\nLog: %s' \
    "$RESULT_DETAIL" \
    "$SOURCE_BYTES_BEFORE" \
    "$SOURCE_BYTES_AFTER" \
    "$DEST1_DAYS_MOVED" \
    "$DEST1_BYTES_MOVED" \
    "$DEST2_DAYS_MOVED" \
    "$DEST2_BYTES_MOVED" \
    "$CAPACITY_EXHAUSTED" \
    "$status" \
    "$LOG_FILE"

  if [[ -z "$EMAIL_RECIPIENT" || "$EMAIL_RECIPIENT" == "your-email@gmail.com" ]]; then
    echo "Error: EMAIL_RECIPIENT is not configured; notification was not sent." >&2
    status=1
  elif ! command -v mail &>/dev/null; then
    echo "Error: Required mail command is unavailable; notification was not sent." >&2
    status=1
  elif printf '%s\n' "$body" | mail -s "$subject" "$EMAIL_RECIPIENT"; then
    echo "Notification submitted to $EMAIL_RECIPIENT."
  else
    echo "Error: Failed to submit notification to $EMAIL_RECIPIENT." >&2
    status=1
  fi

  echo "Script finished with status $status."
  exit "$status"
}

trap finalize EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

main() {
  local source_dev
  local dest1_dev
  local dest2_dev
  local source_root
  local current_dest_index=0
  local resume_dest_index=-1
  local stop_processing=0
  local entry
  local name
  local date_size
  local date_overhead
  local required_size
  local available
  local usable
  local destination
  local filesystem_type
  local canonical
  local expected_device
  local dest_date_dir
  local dest1_date_dir
  local dest2_date_dir
  local dest1_state_dir
  local dest2_state_dir
  local dest1_resume_marker
  local dest2_resume_marker
  local dest1_closed_marker
  local resume_marker
  local dest1_closed=0
  local transfer_started
  local transfer_elapsed
  local transfer_rate
  local -a devices=()
  local -a canonical_devices=()
  local -a date_dirs=()
  local -a source_entries=()
  local -a destination_mounts=("$DEST1_MNT" "$DEST2_MNT")
  local command

  if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root. Please use sudo." >&2
    return 1
  fi

  if [[ $# -ne 3 ]]; then
    echo "Error: Incorrect number of arguments supplied." >&2
    usage >&2
    return 1
  fi

  source_dev="$1"
  dest1_dev="$2"
  dest2_dev="$3"
  devices=("$source_dev" "$dest1_dev" "$dest2_dev")

  exec >"$LOG_FILE" 2>&1
  echo "Starting Frigate recording archive at $(date --iso-8601=seconds)."
  echo "Source: $source_dev"
  echo "Destination 1: $dest1_dev"
  echo "Destination 2: $dest2_dev"

  for command in blkid date df du find findmnt mail mapfile mkdir mount mountpoint readlink rm rsync sync touch umount; do
    if ! command -v "$command" &>/dev/null; then
      echo "Error: Required command '$command' is unavailable." >&2
      return 1
    fi
  done

  if [[ -z "$EMAIL_RECIPIENT" || "$EMAIL_RECIPIENT" == "your-email@gmail.com" ]]; then
    echo "Error: Configure EMAIL_RECIPIENT before running this script." >&2
    return 1
  fi

  for entry in "${devices[@]}"; do
    if [[ ! -b "$entry" ]]; then
      echo "Error: $entry is not a block device." >&2
      return 1
    fi

    if ! canonical=$(readlink -f -- "$entry"); then
      echo "Error: Failed to resolve block device $entry." >&2
      return 1
    fi
    canonical_devices+=("$canonical")

    if findmnt -rn -S "$canonical" &>/dev/null; then
      echo "Error: $entry is already mounted. Unmount all three partitions first." >&2
      return 1
    fi

    if ! filesystem_type=$(blkid -s TYPE -o value -- "$canonical"); then
      echo "Error: Unable to determine the filesystem type for $entry." >&2
      return 1
    fi
    if [[ "$filesystem_type" != "ext4" ]]; then
      echo "Error: $entry uses $filesystem_type; ext4 is required." >&2
      return 1
    fi
  done

  if [[ "${canonical_devices[0]}" == "${canonical_devices[1]}" ||
        "${canonical_devices[0]}" == "${canonical_devices[2]}" ||
        "${canonical_devices[1]}" == "${canonical_devices[2]}" ]]; then
    echo "Error: Source and destination partitions must all be distinct." >&2
    return 1
  fi

  for entry in "$SOURCE_MNT" "$DEST1_MNT" "$DEST2_MNT"; do
    if [[ -L "$entry" ]]; then
      echo "Error: Mount point $entry must not be a symbolic link." >&2
      return 1
    fi
    if mountpoint -q -- "$entry"; then
      echo "Error: Mount point $entry is already in use." >&2
      return 1
    fi
  done

  if ! mkdir -p -- "$SOURCE_MNT" "$DEST1_MNT" "$DEST2_MNT"; then
    echo "Error: Failed to create mount directories." >&2
    return 1
  fi

  echo "Mounting $source_dev at $SOURCE_MNT..."
  if ! mount -o rw,noatime -- "$source_dev" "$SOURCE_MNT"; then
    echo "Error: Failed to mount source $source_dev." >&2
    return 1
  fi
  SOURCE_MOUNTED=1

  echo "Mounting $dest1_dev at $DEST1_MNT..."
  if ! mount -o rw,noatime -- "$dest1_dev" "$DEST1_MNT"; then
    echo "Error: Failed to mount first destination $dest1_dev." >&2
    return 1
  fi
  DEST1_MOUNTED=1

  echo "Mounting $dest2_dev at $DEST2_MNT..."
  if ! mount -o rw,noatime -- "$dest2_dev" "$DEST2_MNT"; then
    echo "Error: Failed to mount second destination $dest2_dev." >&2
    return 1
  fi
  DEST2_MOUNTED=1

  if ! verify_mount "$SOURCE_MNT" "${canonical_devices[0]}" ||
     ! verify_mount "$DEST1_MNT" "${canonical_devices[1]}" ||
     ! verify_mount "$DEST2_MNT" "${canonical_devices[2]}"; then
    echo "Error: A mounted path does not resolve to its expected device." >&2
    return 1
  fi

  source_root="$SOURCE_MNT/$RECORDINGS_DIR"
  if [[ ! -d "$source_root" || -L "$source_root" ]]; then
    echo "Error: Expected source directory $source_root was not found or is a symbolic link." >&2
    return 1
  fi

  if ! mkdir -p -- "$DEST1_MNT/$RECORDINGS_DIR" "$DEST2_MNT/$RECORDINGS_DIR"; then
    echo "Error: Failed to create destination recording directories." >&2
    return 1
  fi
  if [[ -L "$DEST1_MNT/$RECORDINGS_DIR" || -L "$DEST2_MNT/$RECORDINGS_DIR" ]]; then
    echo "Error: Destination recording directories must not be symbolic links." >&2
    return 1
  fi

  dest1_state_dir="$DEST1_MNT/$RECORDINGS_DIR/.clone_disk_state"
  dest2_state_dir="$DEST2_MNT/$RECORDINGS_DIR/.clone_disk_state"
  if [[ -L "$dest1_state_dir" || -L "$dest2_state_dir" ]]; then
    echo "Error: Destination state directories must not be symbolic links." >&2
    return 1
  fi
  if ! mkdir -p -- "$dest1_state_dir" "$dest2_state_dir"; then
    echo "Error: Failed to create destination state directories." >&2
    return 1
  fi

  dest1_closed_marker="$dest1_state_dir/destination_closed"
  if [[ -L "$dest1_closed_marker" ]]; then
    echo "Error: Destination 1 closure marker must not be a symbolic link." >&2
    return 1
  fi
  if [[ -e "$dest1_closed_marker" ]]; then
    if [[ ! -f "$dest1_closed_marker" ]]; then
      echo "Error: Destination 1 closure marker is invalid." >&2
      return 1
    fi
    dest1_closed=1
    current_dest_index=1
    echo "Destination 1 was closed by an earlier run; starting with destination 2."
  fi

  if ! SOURCE_BYTES_BEFORE=$(get_tree_size "$source_root"); then
    echo "Error: Failed to measure the source recording directory." >&2
    return 1
  fi

  shopt -s nullglob dotglob
  source_entries=("$source_root"/*)
  shopt -u nullglob dotglob

  for entry in "${source_entries[@]}"; do
    name="${entry##*/}"
    if [[ -d "$entry" && ! -L "$entry" && "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] &&
       [[ "$(date -d "$name" +%F 2>/dev/null)" == "$name" ]]; then
      date_dirs+=("$entry")
    else
      echo "Warning: Leaving unexpected source entry untouched: $entry"
    fi
  done

  if (( ${#date_dirs[@]} == 0 )); then
    RESULT_DETAIL="No YYYY-MM-DD recording directories were found."
    SOURCE_BYTES_AFTER="$SOURCE_BYTES_BEFORE"
    return 0
  fi

  echo "Found ${#date_dirs[@]} date directories."

  for entry in "${date_dirs[@]}"; do
    name="${entry##*/}"
    resume_dest_index=-1
    dest1_date_dir="$DEST1_MNT/$RECORDINGS_DIR/$name"
    dest2_date_dir="$DEST2_MNT/$RECORDINGS_DIR/$name"
    dest1_resume_marker="$dest1_state_dir/$name"
    dest2_resume_marker="$dest2_state_dir/$name"

    if [[ -L "$dest1_date_dir" || -L "$dest2_date_dir" ||
          -L "$dest1_resume_marker" || -L "$dest2_resume_marker" ]]; then
      echo "Error: Destination date paths and state markers must not be symbolic links: $name" >&2
      return 1
    fi
    if { [[ -e "$dest1_date_dir" ]] || [[ -e "$dest1_resume_marker" ]]; } &&
       { [[ -e "$dest2_date_dir" ]] || [[ -e "$dest2_resume_marker" ]]; }; then
      echo "Error: $name exists on both destination disks; refusing to split a date." >&2
      return 1
    fi
    if [[ -e "$dest1_date_dir" || -e "$dest1_resume_marker" ]]; then
      if [[ ! -d "$dest1_date_dir" || ! -f "$dest1_resume_marker" ]]; then
        echo "Error: Unmarked destination date already exists: $dest1_date_dir" >&2
        return 1
      fi
      current_dest_index=0
      resume_dest_index=0
      echo "Resuming interrupted date $name on destination 1."
    elif [[ -e "$dest2_date_dir" || -e "$dest2_resume_marker" ]]; then
      if [[ ! -d "$dest2_date_dir" || ! -f "$dest2_resume_marker" ]]; then
        echo "Error: Unmarked destination date already exists: $dest2_date_dir" >&2
        return 1
      fi
      current_dest_index=1
      resume_dest_index=1
      echo "Resuming interrupted date $name on destination 2."
    fi

    if ! date_size=$(get_tree_size "$entry"); then
      echo "Error: Failed to measure $entry." >&2
      return 1
    fi
    date_overhead=$((date_size / 100))
    if (( date_overhead < MIN_DATE_OVERHEAD_BYTES )); then
      date_overhead=$MIN_DATE_OVERHEAD_BYTES
    fi
    required_size=$((date_size + date_overhead))

    while true; do
      destination="${destination_mounts[$current_dest_index]}"
      if ! available=$(get_available_bytes "$destination"); then
        echo "Error: Failed to determine available space on $destination." >&2
        return 1
      fi

      if (( available > SAFETY_MARGIN_BYTES )); then
        usable=$((available - SAFETY_MARGIN_BYTES))
      else
        usable=0
      fi

      if (( required_size <= usable )); then
        break
      fi

      if (( resume_dest_index >= 0 )); then
        echo "Error: The remaining files for $name no longer fit on their existing destination." >&2
        return 1
      fi

      if (( current_dest_index == 0 )); then
        echo "$name requires an estimated $required_size bytes and does not fit on destination 1; switching to destination 2."
        if ! verify_mount "$dest1_state_dir" "${canonical_devices[1]}"; then
          echo "Error: Destination 1 mount identity changed before closing it." >&2
          return 1
        fi
        if ! touch -- "$dest1_closed_marker" || ! sync -f -- "$dest1_closed_marker"; then
          echo "Error: Failed to persist the destination 1 closure marker." >&2
          return 1
        fi
        dest1_closed=1
        current_dest_index=1
      else
        echo "$name requires an estimated $required_size bytes and does not fit on destination 2."
        CAPACITY_EXHAUSTED=1
        stop_processing=1
        break
      fi
    done

    if (( stop_processing )); then
      break
    fi

    destination="${destination_mounts[$current_dest_index]}"
    expected_device="${canonical_devices[$((current_dest_index + 1))]}"
    if ! verify_mount "$source_root" "${canonical_devices[0]}" ||
       ! verify_mount "$destination/$RECORDINGS_DIR" "$expected_device"; then
      echo "Error: Source or destination mount identity changed before transferring $name." >&2
      return 1
    fi

    dest_date_dir="$destination/$RECORDINGS_DIR/$name"
    if (( current_dest_index == 0 )); then
      resume_marker="$dest1_resume_marker"
    else
      resume_marker="$dest2_resume_marker"
    fi
    if ! mkdir -p -- "$dest_date_dir" || ! touch -- "$resume_marker"; then
      echo "Error: Failed to create the transfer marker for $name." >&2
      return 1
    fi

    echo "Moving $name ($date_size bytes) to $destination/$RECORDINGS_DIR/..."
    transfer_started=$(date +%s)
    if ! rsync -aHAXx --numeric-ids --remove-source-files --info=progress2 -- \
      "$entry" "$destination/$RECORDINGS_DIR/"; then
      echo "Error: Rsync failed while moving $name." >&2
      return 1
    fi
    transfer_elapsed=$(( $(date +%s) - transfer_started ))
    if (( transfer_elapsed > 0 )); then
      transfer_rate=$((date_size / transfer_elapsed))
    else
      transfer_rate=$date_size
    fi
    echo "Transferred $name in ${transfer_elapsed}s (average ${transfer_rate} bytes/s)."

    if ! verify_mount "$source_root" "${canonical_devices[0]}" ||
       ! verify_mount "$destination/$RECORDINGS_DIR" "$expected_device"; then
      echo "Error: Source or destination mount identity changed while transferring $name." >&2
      return 1
    fi

    if ! find "$entry" -xdev -depth -type d -empty -delete; then
      echo "Error: Failed to delete empty source directories under $entry." >&2
      return 1
    fi

    if [[ -e "$entry" ]]; then
      echo "Error: Source date directory $entry was not empty after transfer." >&2
      return 1
    fi

    if ! rm -f -- "$resume_marker"; then
      echo "Error: Failed to remove the completed transfer marker for $name." >&2
      return 1
    fi

    if (( current_dest_index == 0 )); then
      DEST1_BYTES_MOVED=$((DEST1_BYTES_MOVED + date_size))
      DEST1_DAYS_MOVED=$((DEST1_DAYS_MOVED + 1))
    else
      DEST2_BYTES_MOVED=$((DEST2_BYTES_MOVED + date_size))
      DEST2_DAYS_MOVED=$((DEST2_DAYS_MOVED + 1))
    fi
    if (( dest1_closed )); then
      current_dest_index=1
    fi
    echo "Completed $name and removed its empty source directories."
  done

  if ! SOURCE_BYTES_AFTER=$(get_tree_size "$source_root"); then
    echo "Error: Failed to measure remaining source recordings." >&2
    return 1
  fi

  if (( CAPACITY_EXHAUSTED )); then
    RESULT_DETAIL="Both destination disks reached their usable capacity; remaining source dates were left untouched."
  else
    RESULT_DETAIL="All matching source date directories were transferred successfully."
  fi

  echo "$RESULT_DETAIL"
  echo "Source bytes before: $SOURCE_BYTES_BEFORE"
  echo "Source bytes after: $SOURCE_BYTES_AFTER"
  echo "Destination 1 moved $DEST1_DAYS_MOVED dates and $DEST1_BYTES_MOVED bytes."
  echo "Destination 2 moved $DEST2_DAYS_MOVED dates and $DEST2_BYTES_MOVED bytes."
  return 0
}

main "$@"
exit $?
