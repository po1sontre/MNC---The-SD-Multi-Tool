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

# Function to detect and let user select the SD card device and mount point
select_sd_card() {
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
    sudo cp -v "$src" "$dest" | tee /dev/tty
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
            read -p "Are you sure you want to delete $(basename "$file")? (yes/no): " choice
            if [ "$choice" == "yes" ]; then
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

    echo "Select a file to copy from $SOURCE_DIR:"
    PS3="Enter the number of the file to copy: "
    select file in "$SOURCE_DIR"/*; do
        if [ -f "$file" ]; then
            echo "You selected: $(basename "$file")"
            display_file_size "$file"
            
            target_file="$TARGET_DIR/$(basename "$file")"
            if confirm_overwrite "$target_file"; then
                echo "Copying $(basename "$file") to $TARGET_DIR..."
                copy_with_progress "$file" "$TARGET_DIR"
                echo "Copied $(basename "$file") to $TARGET_DIR"
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
    sudo cp -r "$MOUNT_POINT/"* "$DEST_DIR/"
    if [ $? -eq 0 ]; then
        echo "All files copied to $DEST_DIR."
    else
        echo "An error occurred during the copy process. Please check if the SD card and destination directory are correct."
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
    sudo cp -r "$SOURCE_DIR/"* "$MOUNT_POINT/"
    if [ $? -eq 0 ]; then
        echo "All files copied to SD card."
    else
        echo "An error occurred during the copy process. Please check if the source directory and SD card are correct."
        exit 1
    fi
}

# Function to format the SD card
format_sd() {
    echo "Select a file system to format the SD card:"
    echo "1. FAT32"
    echo "2. exFAT"
    echo "3. NTFS"
    read -p "Enter your choice [1-3]: " fs_choice

    case $fs_choice in
        1)
            FS_TYPE="vfat"
            FS_COMMAND="mkfs.vfat"
            ;;
        2)
            FS_TYPE="exfat"
            FS_COMMAND="mkfs.exfat"
            ;;
        3)
            FS_TYPE="ntfs"
            FS_COMMAND="mkfs.ntfs"
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, or 3."
            return
            ;;
    esac

    echo "Warning: This will erase all data on the SD card!"
    read -p "Are you sure you want to format the SD card? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Formatting cancelled."
        return
    fi

    echo "Formatting the SD card as $FS_TYPE..."
    sudo umount "$SD_CARD_DEVICE"
    sudo $FS_COMMAND "$SD_CARD_DEVICE"

    if [ $? -eq 0 ]; then
        echo "SD card formatted successfully as $FS_TYPE."
        # Remount the SD card after formatting
        echo "Remounting the SD card..."
        sudo mount -o rw,errors=continue "$SD_CARD_DEVICE" "$MOUNT_POINT"
        if [ $? -eq 0 ]; then
            echo "SD card mounted successfully."
        else
            echo "Failed to remount SD card. Please check the device and try again."
        fi
    else
        echo "Failed to format the SD card. Please check the device and try again."
    fi
}

# Function to handle the backup menu
backup_menu() {
    while true; do
        echo "---------------------------------------------------"
        echo "Backup Menu"
        echo "1. Copy all files from SD card to a directory"
        echo "2. Copy all files from a directory to SD card"
        echo "3. Return to main menu"
        echo "---------------------------------------------------"
        read -p "Enter your choice [1-3]: " backup_choice

        case $backup_choice in
            1)
                echo "Enter the destination directory for copying files from SD card:"
                read -p "Destination Directory: " dest_dir
                copy_all_from_sd "$dest_dir"
                ;;
            2)
                echo "Select a source directory:"
                PS3="Enter the number of the source directory: "
                select dir in "$HOME"/*/; do
                    if [ -d "$dir" ]; then
                        copy_all_to_sd "$dir"
                        break
                    else
                        echo "Invalid selection. Please choose a valid directory."
                    fi
                done
                ;;
            3)
                break
                ;;
            *)
                echo "Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
}

# Display the welcome message
welcome_message

# Detect SD card device and mount point
select_sd_card

# Main menu
while true; do
    echo "---------------------------------------------------"
    echo "Choose an option:"
    echo "1. Copy a file to the SD card"
    echo "2. Delete a file from the SD card"
    echo "3. Backup Menu"
    echo "4. Format SD Card"
    echo "5. Set a new source directory"
    echo "6. Exit"
    echo "---------------------------------------------------"
    echo "Note: You must set the source directory before copying files."
    read -p "Enter your choice [1-6]: " choice

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
            break
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, 3, 4, 5, or 6."
            ;;
    esac
done

# Unmount the SD card
sudo umount "$MOUNT_POINT"
echo "SD card unmounted successfully."

echo "---------------------------------------------------"
echo "Thank you for using MNC - The SD Multi Tool!"
echo "---------------------------------------------------"
