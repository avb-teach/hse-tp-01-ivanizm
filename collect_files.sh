#!/bin/bash

usage() {
    echo "Usage: $0 [--max_depth N] <input_directory> <output_directory>"
    echo "Options:"
    echo "  --max_depth N  Limit the depth of directory traversal to N levels"
    exit 1
}

max_depth=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: --max_depth requires a positive integer"
                usage
            fi
            max_depth="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -ne 2 ]]; then
    usage
fi

input_dir="$1"
output_dir="$2"

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

mkdir -p "$output_dir"

resolve_name_conflict() {
    local dest_path="$1"
    local base_name=$(basename "$dest_path")
    local dir_name=$(dirname "$dest_path")
    local name="${base_name%.*}"
    local ext=""
    
    if [[ "$base_name" =~ \..+$ ]]; then
        ext=".${base_name##*.}"
    fi
    
    local counter=1
    local new_path="$dest_path"
    
    while [[ -e "$new_path" ]]; do
        new_path="${dir_name}/${name}${counter}${ext}"
        ((counter++))
    done
    
    echo "$new_path"    
}

if [[ -n "$max_depth" ]]; then
    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f -print0 | while IFS= read -r -d '' file; do
        dest_file="$output_dir/$(basename "$file")"
        if [[ -e "$dest_file" ]]; then
            dest_file=$(resolve_name_conflict "$dest_file")
        fi
        cp -n -- "$file" "$dest_file"
    done
else
    find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
        dest_file="$output_dir/$(basename "$file")"
        if [[ -e "$dest_file" ]]; then
            dest_file=$(resolve_name_conflict "$dest_file")
        fi
        cp -n -- "$file" "$dest_file"
    done
fi

echo "Files copied successfully from $input_dir to $output_dir"