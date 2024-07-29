# MNC - The SD Multi Tool

## Overview

MNC is a command-line utility designed to help manage files on an SD card. It provides functionality for copying, deleting, and backing up files, formatting the SD card with various file systems, and setting up a source directory for file operations.

## Features

- **Detect and Mount SD Card**: Automatically detect and mount your SD card, or manually specify the device and mount point.
- **File Operations**: Copy files to/from the SD card and delete files from the SD card.
- **Backup**: Backup files between the SD card and a local directory.
- **Formatting**: Format the SD card with FAT32, exFAT, or NTFS file systems.
- **Source Directory Management**: Set and manage the source directory for file operations.

## Installation

1. **Download the Script**: Save the script to a file, e.g., `sd_multi_tool.sh`.
2. **Make the Script Executable**:
   ```bash
   chmod +x sd_multi_tool.sh

Usage

To run the tool, execute the script from the command line:

bash

./sd_multi_tool.sh

Main Menu Options

After starting the script, you'll be presented with the following options:

    Copy a File to the SD Card
        Set a source directory before selecting files.
        Choose a file from the source directory to copy to the SD card.

    Delete a File from the SD Card
        List files currently on the SD card.
        Select a file to delete or type 'exit' to cancel.

    Backup Menu
        Copy all files from SD Card to a Directory: Specify a local directory to copy files from the SD card.
        Copy all files from a Directory to SD Card: Choose a local directory to copy files to the SD card.
        Return to Main Menu: Go back to the main menu.

    Format SD Card
        Choose a file system to format the SD card (FAT32, exFAT, NTFS).
        Confirm the formatting operation, which will erase all data on the SD card.

    Set a New Source Directory
        List directories in your home directory.
        Select a directory to use as the source for file operations.

    Exit
        Exit the tool.

Detailed Instructions
Selecting and Mounting the SD Card

    List Devices: The script will list all available block devices and their sizes.
    Enter Device Name: Provide the device name (e.g., sda1).
    Enter Mount Point: Specify the mount point or leave blank to create a default one (/media/sdcard).
    Mounting: The script will create the mount point if it doesn't exist and attempt to mount the SD card.

Copying Files

    Set Source Directory: Use the Set a New Source Directory option to set a directory containing files to copy.
    Select File: Choose a file from the source directory and specify the target directory on the SD card.
    Overwrite Confirmation: Confirm if you want to overwrite an existing file on the SD card.

Deleting Files

    List Files: View files currently on the SD card.
    Select File: Choose a file to delete or type 'exit' to cancel.

Backup Operations

    Copy from SD Card: Specify a local directory to copy all files from the SD card.
    Copy to SD Card: Choose a local directory to copy all files to the SD card.

Formatting the SD Card

    Choose File System: Select from FAT32, exFAT, or NTFS.
    Confirm Formatting: Confirm the operation as it will erase all data on the SD card.

Notes

    Ensure you have the necessary permissions to mount and unmount devices.
    The script requires sudo for mounting, copying, and formatting operations.
    Always back up important data before formatting the SD card.

Troubleshooting

    Device Not Detected: Verify the device name and check connections. Use the lsblk command to list block devices.
    Mounting Errors: Ensure the mount point is correct and the device is not already mounted.
    Formatting Issues: Confirm that the file system command (e.g., mkfs.vfat) is installed on your system.

License

This script is provided under the MIT License. See the LICENSE file for more details.
