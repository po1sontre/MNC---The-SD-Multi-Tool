#!/bin/bash
#
# MIT License
#
# Copyright (c) [year] [Your Name or Organization]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Path to the configuration file
CONFIG_FILE="./sd_multi_tool.config"

# Default configuration values
DEFAULT_MOUNT_POINT="/media/sdcard"
DEFAULT_SOURCE_DIR=""

# Function to display ASCII art
display_art() {
    cat <<'EOF'
---------------------------------------------------
,---.    ,---.,---.   .--.    _______
|    \  /    ||    \  |  |   /   __  \
|  ,  \/  ,  ||  ,  \ |  |  | ,_/  \__)
|  |\_   /|  ||  |\_ \|  |,-./  )
|  _( )_/ |  ||  _( )_\  |\  '_ '`)
| (_ o _) |  || (_ o _)  | > (_)  )  __
|  (_,_)  |  ||  (_,_)\  |(  .  .-'_/  )
|  |      |  ||  |    |  | `-'`-'     /
'--'      '--''--'    '--'   `._____.'
---------------------------------------------------
EOF
}

# Function to display a welcome message
welcome_message() {
    clear
    display_art
    echo "Welcome to MNC - The SD Multi Tool!"
    echo "You can copy or delete files from your SD card."
    echo "---------------------------------------------------"
}

# Function to create a default configuration file
create_default_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creating default configuration file..."
        cat <<EOL > "$CONFIG_FILE"
# SD Multi Tool Configuration
MOUNT_POINT="$DEFAULT_MOUNT_POINT"
SOURCE_DIR="$DEFAULT_SOURCE_DIR"
EOL
    fi
}

# Function to load configuration from the file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo "Configuration file not found. Please create it."
        exit 1
    fi
}

# Function to list all block devices and their sizes
list_devices() {
    echo "Listing all block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo "---------------------------------------------------"
}

# Function to handle manual mounting of the SD card
manual_mount_sd() {
    list_devices

    read -p "Enter the name of the SD card device (e.g., sda1): " device_name
    SD_CARD_DEVICE="/dev/$device_name"

    # Check if the device exists
    if [ ! -b "$SD_CARD_DEVICE" ]; then
        echo "Device $SD_CARD_DEVICE does not exist. Please check the device name and try again."
        exit 1
    fi

    # Prompt user for mount point
    read -p "Enter the mount point (e.g., /media/sdcard) [Leave blank to use default]: " mount_point

    # Use a default mount point if the user leaves it blank
    if [ -z "$mount_point" ]; then
        mount_point="$DEFAULT_MOUNT_POINT"
    fi

    MOUNT_POINT="$mount_point"

    # Create mount point if it doesn't exist
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Mount point $MOUNT_POINT does not exist. Creating it now..."
        sudo mkdir -p "$MOUNT_POINT"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory $MOUNT_POINT. Please check permissions."
            exit 1
        fi
    fi

    # Attempt to mount the SD card
    sudo mount "$SD_CARD_DEVICE" "$MOUNT_POINT"
    if [ $? -eq 0 ]; then
        echo "SD card successfully mounted at $MOUNT_POINT."
    else
        echo "Failed to mount SD card. Please check the device and mount point."
        exit 1
    fi
}

# Function to display file size
display_file_size() {
    local file="$1"
    local size
    size=$(du -h "$file" | cut -f1)
    echo "Size of $(basename "$file"): $size"
}

# Function to copy file with progress indicator
copy_with_progress() {
    local src="$1"
    local dest="$2"
    sudo rsync -avh --progress --no-owner --no-group "$src" "$dest" > /tmp/rsync.log 2>&1
}

# Function to handle file overwrite confirmation
confirm_overwrite() {
    local file="$1"
    if [ -f "$file" ]; then
        read -p "File $(basename "$file") already exists on the SD card. Overwrite? (y/n): " choice
        if [ "$choice" != "y" ]; then
            echo "Skipping $(basename "$file")."
            return 1
        fi
    fi
    return 0
}

# Function to list files in the target directory
list_target_files() {
    echo "Files currently on the SD card:"
    ls "$TARGET_DIR"
    echo "---------------------------------------------------"
}

# Function to delete a file from the SD card
delete_file() {
    list_target_files
    echo "Select a file to delete (or type 'exit' to cancel):"
    PS3="Enter the number of the file to delete: "
    select file in "$TARGET_DIR"/*; do
        if [ "$file" == "exit" ]; then
            echo "Exiting deletion process."
            break
        elif [ -f "$file" ]; then
            read -p "Are you sure you want to delete $(basename "$file")? (y/n): " choice
            if [ "$choice" == "y" ]; then
                sudo rm -v "$file"
                echo "Deleted $(basename "$file") from $TARGET_DIR"
            else
                echo "Skipping $(basename "$file")."
            fi
        else
            echo "Invalid selection. Please choose a valid file or type 'exit'."
        fi
        break
    done
}

# Function to copy a file to the SD card
copy_file() {
    if [ -z "$SOURCE_DIR" ]; then
        echo "Source directory is not set. Please set the source directory first."
        return
    fi

    if [ -z "$MOUNT_POINT" ]; then
        echo "Target directory is not set. Please set the target directory before copying files."
        return
    fi

    echo "Select a file to copy from $SOURCE_DIR:"
    PS3="Enter the number of the file to copy: "
    select file in "$SOURCE_DIR"/*; do
        if [ -f "$file" ]; then
            echo "You selected: $(basename "$file")"
            display_file_size "$file"

            target_file="$MOUNT_POINT/$(basename "$file")"
            if confirm_overwrite "$target_file"; then
                echo "Starting copy of $(basename "$file") to $MOUNT_POINT..."

                # Ensure that the destination path is not empty
                if [ -z "$MOUNT_POINT" ]; then
                    echo "Destination directory is not set. Cannot copy file."
                    return
                fi

                # Use rsync for copying with detailed progress and error logging
                copy_with_progress "$file" "$MOUNT_POINT/"
                if [ $? -eq 0 ]; then
                    echo "Copied $(basename "$file") to $MOUNT_POINT"
                else
                    echo "Failed to copy file. Check /tmp/rsync.log for details."
                fi
            fi
        else
            echo "Invalid selection. Please choose a valid file."
        fi
        break
    done
}

# Function to set the source directory by listing directories in the home directory
set_source_dir() {
    echo "Select a source directory:"
    local dirs=("$HOME"/*/)
    PS3="Enter the number of the source directory: "
    select dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            SOURCE_DIR="$dir"
            echo "Source directory set to $SOURCE_DIR"
            break
        else
            echo "Invalid selection. Please choose a valid directory."
        fi
    done
}

# Function to display a backup menu (optional functionality)
backup_menu() {
    echo "Backup menu not implemented yet."
}

# Function to format the SD card
format_sd() {
    echo "Warning: This will erase all data on the SD card."
    read -p "Are you sure you want to format the SD card? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "Format operation cancelled."
        return
    fi

    sudo mkfs.vfat "$SD_CARD_DEVICE"
    if [ $? -eq 0 ]; then
        echo "SD card formatted successfully."
    else
        echo "Failed to format SD card."
    fi
}

# Function to show version information
show_version() {
    echo "SD Multi Tool Version 1.0"
}

# Main script execution
welcome_message
create_default_config
load_config

# Ensure the mount point exists and is properly set
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Mount point $MOUNT_POINT does not exist. Please mount the SD card manually."
    exit 1
fi

# Main menu loop
while true; do
    echo "---------------------------------------------------"
    echo "Choose an option:"
    echo "1. Copy a file to the SD card"
    echo "2. Delete a file from the SD card"
    echo "3. Backup Menu"
    echo "4. Format SD Card"
    echo "5. Set a new source directory"
    echo "6. Mount SD Card (manual)"
    echo "7. Show version information"
    echo "8. Exit"
    echo "---------------------------------------------------"
    echo "Note: You must set the source directory before copying files."
    read -p "Enter your choice [1-8]: " choice

    case $choice in
        1)
            copy_file
            ;;
        2)
            delete_file
            ;;
        3)
            backup_menu
            ;;
        4)
            format_sd
            ;;
        5)
            set_source_dir
            ;;
        6)
            manual_mount_sd
            ;;
        7)
            show_version
            ;;
        8)
            break
            ;;
        *)
            echo "Invalid choice. Please select 1-8."
            ;;
    esac
done

# Unmount the SD card automatically on exit
trap 'if mountpoint -q "$MOUNT_POINT"; then sudo umount "$MOUNT_POINT"; echo "SD card unmounted successfully."; fi' EXIT

