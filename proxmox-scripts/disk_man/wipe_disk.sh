#!/bin/bash

# ==============================================================================
# WARNING: THIS SCRIPT IS EXTREMELY DESTRUCTIVE AND IRREVERSIBLE.
# It will completely erase all data on the device specified as an argument.
#
# USAGE: nohup sudo ./wipe_disk.sh /dev/sdc &
# ==============================================================================

# === Configuration ===
LOG_FILE="/var/log/disk_wipe.log"
SCRIPT_NAME="Disk Wipe Utility"
EMAIL_RECIPIENT="root@pam"
PROXMOX_MAILER="/usr/bin/proxmox-mail-forward"

# === Helper Function for Logging ===
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
}

# === Main Script ===

# --- Initialize Log File ---
sudo truncate -s 0 "$LOG_FILE"
log_message "======= Starting $SCRIPT_NAME Script ======="

# --- CRITICAL SAFETY CHECKS ---
# 1. Check if a device was provided as an argument.
if [ "$#" -ne 1 ]; then
    log_message "CRITICAL ERROR: No device specified. Please provide a device as an argument. Aborting."
    printf "Subject: %s: CRITICAL FAILURE\n\nConfiguration error: Script was run without specifying a target device." "[$SCRIPT_NAME]" | sudo "$PROXMOX_MAILER" "$EMAIL_RECIPIENT"
    exit 1
fi

# Assign the first command-line argument to WIPE_DEVICE
WIPE_DEVICE="$1"

log_message "CONFIG: Target device for wipe is set to $WIPE_DEVICE"

# 2. Check if the device exists as a block device.
if [ ! -b "$WIPE_DEVICE" ]; then
    log_message "CRITICAL ERROR: Device $WIPE_DEVICE does not exist or is not a block device. Aborting."
    printf "Subject: %s: CRITICAL FAILURE\n\nValidation error: The specified device %s could not be found." "[$SCRIPT_NAME]" "$WIPE_DEVICE" | sudo "$PROXMOX_MAILER" "$EMAIL_RECIPIENT"
    exit 1
fi

# 3. Check if the device or any of its partitions are mounted.
if findmnt -n "$WIPE_DEVICE" >/dev/null; then
    MOUNT_INFO=$(findmnt -n -o TARGET --source "$WIPE_DEVICE")
    log_message "CRITICAL ERROR: Device $WIPE_DEVICE or its partitions are currently mounted at: $MOUNT_INFO. Aborting."
    printf "Subject: %s: CRITICAL FAILURE\n\nSafety error: Attempted to wipe a mounted device (%s)." "[$SCRIPT_NAME]" "$WIPE_DEVICE" | sudo "$PROXMOX_MAILER" "$EMAIL_RECIPIENT"
    exit 1
fi

log_message "Safety checks passed. Proceeding with wipe operation."

# --- ## DISK WIPE OPERATION ## ---
log_message "Starting 'dd' to write zeros to $WIPE_DEVICE. This will take a very long time."
START_TIME=$(date +%s)

# Execute the dd command, redirecting all output (stdout and stderr) to the log file.
# The 'status=progress' output goes to stderr, so '&>>' is crucial for logging it.
sudo dd if=/dev/zero of="$WIPE_DEVICE" bs=4M status=progress &>> "$LOG_FILE"
DD_STATUS=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
WIPE_MESSAGE_DETAIL=""
FINAL_EXIT_CODE=0
EMAIL_SUBJECT_STATUS=""

# Check for success (exit code 0) OR the specific, benign "no space left" error.
if [ $DD_STATUS -eq 0 ] || { [ $DD_STATUS -eq 1 ] && grep -q "No space left on device" "$LOG_FILE"; }; then
    if [ $DD_STATUS -eq 0 ]; then
        log_message "dd operation completed perfectly."
    else
        log_message "dd operation finished with expected 'No space left on device' error. This is considered a success for a full disk wipe."
    fi

    WIPE_MESSAGE_DETAIL="Successfully wiped $WIPE_DEVICE."
    EMAIL_SUBJECT_STATUS="SUCCESS"

    # --- Create a new GPT partition table ---
    log_message "Creating a new GPT partition table on $WIPE_DEVICE..."
    sudo parted "$WIPE_DEVICE" mklabel gpt &>> "$LOG_FILE"
    PARTED_STATUS=$?

    if [ $PARTED_STATUS -eq 0 ]; then
        log_message "Successfully created new GPT partition table."
        WIPE_MESSAGE_DETAIL+="\nA new GPT partition table has been created. The drive is now blank and ready for partitioning."
    else
        log_message "ERROR: Failed to create GPT partition table with exit code $PARTED_STATUS."
        WIPE_MESSAGE_DETAIL+="\nWARNING: Failed to create a new GPT partition table (Code: $PARTED_STATUS). The drive is wiped but may require manual partitioning."
        EMAIL_SUBJECT_STATUS="SUCCESS WITH PARTITIONING ERROR"
        FINAL_EXIT_CODE=$PARTED_STATUS
    fi
else
    # All other errors are still treated as failures.
    log_message "ERROR: dd operation failed with a critical error (exit code $DD_STATUS)."
    WIPE_MESSAGE_DETAIL="Disk wipe FAILED on $WIPE_DEVICE with exit code $DD_STATUS."
    EMAIL_SUBJECT_STATUS="FAILURE"
    FINAL_EXIT_CODE=$DD_STATUS
fi

# --- Send Email Notification ---
log_message "Preparing email notification..."

EMAIL_SUBJECT="[$SCRIPT_NAME]: $EMAIL_SUBJECT_STATUS"
FORMATTED_DURATION=$(printf '%02dh:%02dm:%02ds' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

# Construct email body
EMAIL_BODY="Disk wipe script has finished.\n"
EMAIL_BODY+="Target Device: $WIPE_DEVICE\n"
EMAIL_BODY+="Total Duration: $FORMATTED_DURATION\n\n"
EMAIL_BODY+="Result: $WIPE_MESSAGE_DETAIL\n\n"
EMAIL_BODY+="See the log file for full details: $LOG_FILE\n"

# Send the email using the Proxmox mailer
log_message "Sending email notification to $EMAIL_RECIPIENT..."
printf "Subject: %s\n\n%s" "$EMAIL_SUBJECT" "$EMAIL_BODY" | sudo "$PROXMOX_MAILER" "$EMAIL_RECIPIENT"

if [ $? -eq 0 ]; then
    log_message "Email notification sent successfully."
else
    log_message "ERROR: Failed to send email notification."
    if [ $FINAL_EXIT_CODE -eq 0 ]; then FINAL_EXIT_CODE=1; fi # Set a generic error code if one isn't already set
fi

log_message "======= $SCRIPT_NAME Script Finished ======="
echo "" >> "$LOG_FILE" # Add a blank line for readability between runs

exit $FINAL_EXIT_CODE
