#!/bin/bash

# This script downloads images from a URL and saves them to a mapping assert directory.

SCRIPT_NAME=$(basename $0)
BASE_PATH=$(cd `dirname $0`; pwd)
ROOT_PATH=$(cd `dirname $0`; cd ..; pwd)

NOTE_PATH=
DONOT_SKIP_BACKUP_REPLACEMENT=
FORCE_DOWNLOAD_ALL_THE_LINKS=


download_image_for_single_markdown() {
    IFS=$'\n'

    MARKDOWN_FILE=$1
    DONOT_SKIP_BACKUP_REPLACEMENT=$DONOT_SKIP_BACKUP_REPLACEMENT

    DOWNLOAD_DIR="${MARKDOWN_FILE%.*}.assets"
    DOWNLOAD_DIR_NAME="$(basename $DOWNLOAD_DIR)"
    DOWNLOAD_DIR_NAME_NOSPACE=${DOWNLOAD_DIR_NAME// /%20}
    DOWNLOAD_SOURCE_NOTES="$DOWNLOAD_DIR/.sourcenotes"
    BACKUP_MARKDOWN_FILE="$DOWNLOAD_DIR/$DOWNLOAD_DIR_NAME.md.orig"

    count_image=0
    count_image_exist=0
    count_image_success=0
    count_image_fail=0
    count_image_skip=0
    declare -A dict_replaced_images

    # get all the image url from Markdown file and download them
    for line in $(grep -oP '\!\[.*\]\(.*\)' "$MARKDOWN_FILE"); do
        let count_image=$count_image+1
        # get the URL from the Markdown image link
        imageurl=$(grep -oP '\(\K[^)]+' <<< "$line")

        # generate random imagename
        imagename="$(echo $imageurl | md5sum | awk '{print $1}').${imageurl##*.}"
        
        imagepath="$DOWNLOAD_DIR/$imagename"

        echo $DOWNLOAD_DIR
        echo "Handling URL: $imageurl"
        echo "Filename: $imagename"
        echo "Path: $imagepath"

        mkdir -p "$DOWNLOAD_DIR"

        grep -oP "$imagename $imageurl" $DOWNLOAD_SOURCE_NOTES &> /dev/null
        if [ $? -eq 0 ]; then
            echo "File already exists, skipping download: $imagename"
            let count_image_exist=$count_image_exist+1
            dict_replaced_images["$line"]=$(echo "$line" | sed "s|$imageurl|./$DOWNLOAD_DIR_NAME_NOSPACE/$imagename|g")
            continue
        fi
        
        # only download image files
        if [[ $imageurl =~ \.(jpg|jpeg|png|gif|bmp|svg)$ ]]; then
            echo "Downloading $imagename From $imageurl ..."
            wget -q --show-progress -O "$imagepath" "$imageurl"
            if [ $? -eq 0 ]; then
                echo "Successfully"
                let count_image_success=$count_image_success+1
                echo "$imagename $imageurl" >> "$DOWNLOAD_SOURCE_NOTES"
                dict_replaced_images["$line"]=$(echo "$line" | sed "s|$imageurl|./$DOWNLOAD_DIR_NAME_NOSPACE/$imagename|g")
            else
                echo "Failed"
                let count_image_fail=$count_image_fail+1
            fi
        elif [[ ! -z $FORCE_DOWNLOAD_ALL_THE_LINKS ]] && [[ $imageurl =~ ^https?:// ]]; then
            imagename="$(echo $imageurl | md5sum | awk '{print $1}').png"
            imagepath="$DOWNLOAD_DIR/$imagename"
            echo "Force Downloading $imagename From $imageurl ..."
            wget -q --show-progress -O "$imagepath" "$imageurl"
            if [ $? -eq 0 ]; then
                echo "Successfully"
                let count_image_success=$count_image_success+1
                echo "$imagename $imageurl" >> "$DOWNLOAD_SOURCE_NOTES"
                dict_replaced_images["$line"]=$(echo "$line" | sed "s|$imageurl|./$DOWNLOAD_DIR_NAME_NOSPACE/$imagename|g")
            else
                echo "Failed"
                let count_image_fail=$count_image_fail+1
            fi
        else
            echo "Non-Image URL: $imageurl"
            echo "Skipped"
            let count_image_skip=$count_image_skip+1
        fi
    done

    echo 
    echo "Download Completed."
    echo 
    echo "----------------- Summary Start -----------------"
    echo "Image Total: $count_image"
    echo "Image Download Skip with Exist: $count_image_exist"
    echo "Image Download Success: $count_image_success"
    echo "Image Download Fail: $count_image_fail"
    echo "Image Download Skip: $count_image_skip"
    echo "----------------- Summary   End -----------------"
    echo 

    if [ -z $DONOT_SKIP_BACKUP_REPLACEMENT ] && [ $count_image -eq 0 ]; then
        echo "No image found in the Markdown file. Skip Backup and Replacement."
        return 0
    fi

    if [ -z $DONOT_SKIP_BACKUP_REPLACEMENT ] && [ $count_image_success -eq 0 ]; then
        echo "No image downloaded successfully. Skip Backup and Replacement."
        return 0
    fi

    # Make a backup of the original Markdown file
    if [ -f "$BACKUP_MARKDOWN_FILE" ]; then
        datetime=$(date "+%Y%m%d%H%M%S")
        cp "$MARKDOWN_FILE" "$BACKUP_MARKDOWN_FILE.$datetime"
        echo "Backup Markdown File: $BACKUP_MARKDOWN_FILE.$datetime"
    else
        cp "$MARKDOWN_FILE" "$BACKUP_MARKDOWN_FILE"
        echo "Backup Markdown File: $BACKUP_MARKDOWN_FILE"
    fi

    echo "Replacing image links in Markdown file..."
    for item in "${!dict_replaced_images[@]}"; do
        itemnew=${dict_replaced_images[$item]}
        echo "Replacing $item with $itemnew"
        python3 -c "import sys;\
        fr=open(sys.argv[1]);\
        cxt=fr.read();\
        fr.close();\
        fw=open(sys.argv[1],'w');\
        fw.write(cxt.replace(sys.argv[2], sys.argv[3]));\
        " "$MARKDOWN_FILE" "$item" "$itemnew"
    done
    echo "Replacement completed."
}

download_image_for_all_markdown() {
    IFS=$'\n'
    path=$1
    for markdown_file in $(find $path -name "*.md"); do
        echo
        echo "========================= Start Downloading Images for $markdown_file ========================="
        download_image_for_single_markdown $markdown_file
        echo "========================= End Downloading Images for $markdown_file ========================="
        echo 
    done
}

download_image_for_markdown() {
    path=$1
    if [ -d "$path" ]; then
        download_image_for_all_markdown $path
    else
        if [ ! -f "$path" ]; then
            echo "Invalid Path: $path"
            exit 1
        fi
        download_image_for_single_markdown $path
    fi
}

print_usage() {
    echo 
    echo "Usage: $SCRIPT_NAME -p <path>"
    echo "  -a           Download all notes' third-lib images."
    echo "  -b           Do not skip backup and replacement if no image downloaded."
    echo "  -f           Force download all the links."
    echo "  -h           Display this help message."
    echo "  -p <path>    The path to the note directory/filepath."
    echo
    echo "Example: $SCRIPT_NAME -p /path/to/note.md"
    echo "         $SCRIPT_NAME -p /path/to/notedir"
    echo "         $SCRIPT_NAME -a"
    echo 
}

IFS=$'\n'
while getopts "abfhp:" opt; do
    case $opt in
        a)
            echo "Download all notes' third-lib images."
            NOTE_PATH=$ROOT_PATH
            ;;
        b)
            DONOT_SKIP_BACKUP_REPLACEMENT=1
            ;;
        f)
            FORCE_DOWNLOAD_ALL_THE_LINKS=1
            ;;
        h)
            print_usage
            exit 0
            ;;
        p)
            NOTE_PATH=$OPTARG
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            print_usage
            exit 1
            ;;
    esac
done

if [ -z "$NOTE_PATH" ]; then
    print_usage
    exit 1
fi

download_image_for_markdown $NOTE_PATH

