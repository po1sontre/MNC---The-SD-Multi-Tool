```markdown
# SD Multi Tool

## Overview

SD Multi Tool is a versatile script designed to manage files on an SD card. It provides functionalities for copying, deleting, backing up, and formatting SD card contents. The tool supports manual mounting and features error logging to help troubleshoot issues.

## Features

- **Copy Files**: Transfer files from a source directory to the SD card.
- **Delete Files**: Remove files from the SD card.
- **Backup**: Backup files between the SD card and a local directory.
- **Format SD Card**: Format the SD card to FAT32, exFAT, or NTFS.
- **Manual Mounting**: Option to manually mount the SD card if needed.
- **Source Directory Management**: Set and manage the source directory for file operations.
- **Error Logging**: Detailed error logs for troubleshooting.
- **Configuration File**: Automatically create and manage a default configuration file.

## Installation

### Prerequisites

Ensure you have `rsync` installed for file operations. On Arch Linux, you can install it with:

```bash
sudo pacman -S rsync
```

Ensure you have the necessary permissions to mount, unmount drives, and format disks.

### Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/po1sontre/MNC---The-SD-Multi-Tool.git
cd MNC---The-SD-Multi-Tool
```

## Usage

### Initial Setup

1. **Run the Script**: Execute the script for the first time. It will create a default configuration file named `sd_multi_tool.conf` in the same directory.

    ```bash
    ./sd_multi_tool.sh
    ```

2. **Edit Configuration**: Modify the `sd_multi_tool.conf` file to set default values such as the SD card mount point.

### Main Menu Options

1. **Copy a File to the SD Card**:
    - Set the source directory before copying.
    - Select a file to copy from the source directory to the SD card.

2. **Delete a File from the SD Card**:
    - Choose a file to delete from the SD card and confirm the deletion.

3. **Backup Menu**:
    - **Copy All Files from SD Card**: Backup all files from the SD card to a local directory.
    - **Copy All Files to SD Card**: Copy all files from a local directory to the SD card.

4. **Format SD Card**:
    - Select a file system (FAT32, exFAT, or NTFS) and confirm formatting.

5. **Set a New Source Directory**:
    - Choose a new source directory for file operations.

6. **Mount SD Card (Manual)**:
    - Display all available block devices with their sizes.
    - Manually specify the device name and mount point.

7. **Show Version Information**:
    - Display the script’s version information.

8. **Exit**:
    - Exit the script.

### Error Handling

- Errors are logged to `/tmp/rsync.log`. Check this file for detailed error messages if something goes wrong.

## Configuration File

The `sd_multi_tool.conf` file is created automatically and can be modified:

```bash
# Example configuration file (sd_multi_tool.conf)
MOUNT_POINT="/media/sdcard"
SOURCE_DIR="$HOME/Downloads"
```

## Notes

- Ensure that the mount point directory exists and is writable.
- Formatting the SD card will erase all data. Ensure that all important data is backed up.

## Contributing

If you have suggestions or improvements, please open an issue or submit a pull request on GitHub.

## License

This script is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits

This script is developed and maintained by [po1sontre](https://github.com/po1sontre). Thanks for your contributions and support!
```


