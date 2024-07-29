#!/bin/bash

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

# Function to list all block devices and their sizes
list_devices() {
    echo "Listing all block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo "---------------------------------------------------"
}

# Function to select and manually mount the SD card device
manual_mount_sd_card() {
    list_devices

    read -p "Enter the name of the SD card device (e.g., sda1): " device_name
    SD_CARD_DEVICE="/dev/$device_name"

    # Check if the device exists
    if [ ! -b "$SD_CARD_DEVICE" ]; then
        echo "Device $SD_CARD_DEVICE does not exist. Please check the device name and try again."
        exit 1
    fi

    # Prompt user for mount point
    read -p "Enter the mount point (e.g., /media/sdcard) [Leave blank to create a default mount point]: " mount_point

    # Use a default mount point if the user leaves it blank
    if [ -z "$mount_point" ]; then
        mount_point="/media/sdcard"
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
    echo "Mounting $SD_CARD_DEVICE at $MOUNT_POINT..."
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

    # Check if rsync is installed
    if ! command -v rsync &> /dev/null; then
        echo "rsync is not installed. Please install rsync and try again."
        exit 1
    fi

    echo "Starting copy of $src to $dest..."
    
    # Use rsync for progress reporting and verbose output
    sudo rsync -avh --progress --no-owner --no-group "$src" "$dest" > /tmp/rsync.log 2>&1
    if [ $? -eq 0 ]; then
        echo "Successfully copied $(basename "$src") to $dest."
    else
        echo "Failed to copy $(basename "$src") to $dest. Check /tmp/rsync.log for details."
        cat /tmp/rsync.log
    fi
    # Pause to review the log
    read -p "Press Enter to continue..."
}

# Function to handle file overwrite confirmation
confirm_overwrite() {
    local file="$1"
    if [ -f "$file" ]; then
        read -p "File $(basename "$file") already exists on the SD card. Overwrite? (yes/no): " choice
        if [ "$choice" != "yes" ]; then
            echo "Skipping $(basename "$file")."
            return 1
        fi
    fi
    return 0
}

# Function to list files in the target directory
list_target_files() {
    echo "Files currently on the SD card:"
    ls "$MOUNT_POINT"
    echo "---------------------------------------------------"
}

# Function to delete a file from the SD card
delete_file() {
    list_target_files
    echo "Select a file to delete (or type 'exit' to cancel):"
    PS3="Enter the number of the file to delete: "
    select file in "$MOUNT_POINT"/*; do
        if [ "$file" == "exit" ]; then
            echo "Exiting deletion process."
            break
        elif [ -f "$file" ]; then
            read -p "Are you sure you want to delete $(basename "$file")? (yes/no): " choice
            if [ "$choice" == "yes" ]; then
                echo "Deleting $(basename "$file")..."
                sudo rm -v "$file"
                echo "Deleted $(basename "$file") from $MOUNT_POINT"
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
        sleep 5
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
                copy_with_progress "$file" "$MOUNT_POINT/"
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

# Function to copy all files from SD card to a specified directory
copy_all_from_sd() {
    local DEST_DIR="$1"

    if [ ! -d "$DEST_DIR" ]; then
        echo "Directory $DEST_DIR does not exist. Creating it now..."
        sudo mkdir -p "$DEST_DIR"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory $DEST_DIR. Please check permissions."
            exit 1
        fi
    fi

    echo "Copying all files from SD card to $DEST_DIR..."
    sudo rsync -avh --progress --no-owner --no-group "$MOUNT_POINT/" "$DEST_DIR/" > /tmp/rsync.log 2>&1
    if [ $? -eq 0 ]; then
        echo "All files copied to $DEST_DIR."
    else
        echo "An error occurred during the copy process. Check /tmp/rsync.log for details."
        cat /tmp/rsync.log
        exit 1
    fi
}

# Function to copy all files from a directory to the SD card
copy_all_to_sd() {
    local SOURCE_DIR="$1"

    if [ ! -d "$SOURCE_DIR" ]; then
        echo "Source directory $SOURCE_DIR does not exist. Please check and try again."
        exit 1
    fi

    echo "Copying all files from $SOURCE_DIR to SD card..."
    sudo rsync -avh --progress --no-owner --no-group "$SOURCE_DIR/" "$MOUNT_POINT/" > /tmp/rsync.log 2>&1
    if [ $? -eq 0 ]; then
        echo "All files copied to SD card."
    else
        echo "An error occurred during the copy process. Check /tmp/rsync.log for details."
        cat /tmp/rsync.log
        exit 1
    fi
}

# Main menu
main_menu() {
    welcome_message
    echo "1. Set source directory"
    echo "2. Copy file to SD card"
    echo "3. Delete file from SD card"
    echo "4. Copy all files from SD card to a directory"
    echo "5. Copy all files from a directory to SD card"
    echo "6. Manually mount SD card"
    echo "7. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) set_source_dir ;;
        2) copy_file ;;
        3) delete_file ;;
        4) 
            read -p "Enter the destination directory: " dest_dir
            copy_all_from_sd "$dest_dir"
            ;;
        5) 
            read -p "Enter the source directory: " src_dir
            copy_all_to_sd "$src_dir"
            ;;
        6) manual_mount_sd_card ;;
        7) exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac

    main_menu
}

main_menu

