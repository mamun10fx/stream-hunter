#!/bin/bash

# Base folder where files will be saved
base_folder="/storage/emulated/0/Stream Videos"

# Utility functions for colored output
print_banner() {
    echo -e "\e[1;34m--------------------------------------------\e[0m"
    echo -e "\e[1;34m           Stream Hunter                  \e[0m"
    echo -e "\e[1;34m--------------------------------------------\e[0m"
}
print_success() {
    echo -e "\e[1;32m$1\e[0m"
}
print_error() {
    echo -e "\e[1;31m$1\e[0m"
}
print_prompt() {
    echo -ne "\e[1;36m$1\e[0m"
}
create_directory_if_not_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Process title: if it contains '/' then use it as a relative path and construct filename.
process_title() {
    local input_title="$1"
    local out_dir out_file
    if [[ "$input_title" == *"/"* ]]; then
        IFS='/' read -ra parts <<< "$input_title"
        local dir_path=""
        for (( i=0; i<${#parts[@]}-1; i++ )); do
            if [ -z "$dir_path" ]; then
                dir_path="${parts[i]}"
            else
                dir_path="$dir_path/${parts[i]}"
            fi
        done
        out_dir="$base_folder/$dir_path"
        local rev=""
        for (( i=${#parts[@]}-1; i>=0; i-- )); do
            if [ -z "$rev" ]; then
                rev="${parts[i]}"
            else
                rev="${rev}_${parts[i]}"
            fi
        done
        out_file="${rev}.mp4"
    else
        out_dir="$base_folder"
        out_file="${input_title}.mp4"
    fi
    create_directory_if_not_exists "$out_dir" >&2
    echo "$out_dir/$out_file"
}

# Download file using ffmpeg with a custom progress display.
download_file() {
    local url="$1"
    local output="$2"
    local bitrate="$3"
    local file_id="$4"
    local type="$5"   # "video" or "audio"
    local total_estimated_mib="$6"   # Estimated total size in MiB (if available)

    if [ "$type" == "video" ]; then
        echo -e "\e[1;36mDownloading video - ${file_id}\e[0m"
    else
        echo -e "\e[1;36mDownloading audio - ${file_id}\e[0m"
    fi

    local ffmpeg_cmd=("ffmpeg" "-loglevel" "quiet" "-i" "$url")
    if [ -n "$bitrate" ]; then
        ffmpeg_cmd+=("-b" "$bitrate")
    fi
    ffmpeg_cmd+=("-c" "copy" "-y" "$output")
    "${ffmpeg_cmd[@]}" &
    local ffmpeg_pid=$!

    local start_time=$(date +%s)
    while kill -0 "$ffmpeg_pid" 2>/dev/null; do
        if [ -f "$output" ]; then
            current_size=$(stat --format="%s" "$output" 2>/dev/null || echo 0)
        else
            current_size=0
        fi
        current_time=$(date +%s)
        elapsed=$(( current_time - start_time ))
        [ $elapsed -eq 0 ] && elapsed=1
        speed_kib=$(awk "BEGIN {printf \"%.0f\", ($current_size/1024)/$elapsed}")
        downloaded_mib=$(awk "BEGIN {printf \"%.2f\", $current_size/1024/1024}")

        if [ "$type" == "video" ]; then
            if [ -n "$total_estimated_mib" ] && [ "$total_estimated_mib" != "0" ]; then
                total_bytes=$(awk "BEGIN {printf \"%d\", $total_estimated_mib*1024*1024}")
                percentage=$(awk "BEGIN {printf \"%.0f\", ($current_size/($total_estimated_mib*1024*1024))*100}")
                if [ "$speed_kib" -gt 0 ]; then
                    eta_sec=$(awk "BEGIN {printf \"%d\", (($total_bytes - $current_size)/( $speed_kib*1024))}")
                else
                    eta_sec=0
                fi
                eta_formatted=$(printf "%02d:%02d" $((eta_sec/60)) $((eta_sec%60)))
            else
                percentage="?"
                total_estimated_mib="?"
                eta_formatted="--:--"
            fi
            progress_line=$(printf "\e[32m[%s%%]\e[0m \e[33m%sMiB\e[0m of ~\e[36m%sMiB\e[0m \e[35m%sKiB/s\e[0m ETA \e[31m%s\e[0m" \
                             "$percentage" "$downloaded_mib" "$total_estimated_mib" "$speed_kib" "$eta_formatted")
        else
            progress_line=$(printf "\e[32m[Audio]\e[0m \e[33m%sMiB\e[0m downloaded" "$downloaded_mib")
        fi
        printf "\r%s" "$progress_line"
        sleep 0.5
    done
    wait "$ffmpeg_pid"
    printf "\n"
}

# Merge video and audio using ffmpeg with a single–line progress display.
merge_files() {
    local video_file="$1"
    local audio_file="$2"
    local output_file="$3"
    if [ -f "$video_file" ] && [ -f "$audio_file" ]; then
         video_size=$(stat --format="%s" "$video_file")
         audio_size=$(stat --format="%s" "$audio_file")
         total_merge_bytes=$((video_size + audio_size))
         total_merge_mib=$(awk "BEGIN {printf \"%.2f\", $total_merge_bytes/1024/1024}")
    else
         total_merge_bytes=0
         total_merge_mib="?"
    fi

    echo -e "Using ffmpeg for merging"

    local ffmpeg_cmd=("ffmpeg" "-loglevel" "error" "-i" "$video_file" "-i" "$audio_file" \
                      "-c:v" "copy" "-c:a" "copy" "-y" "$output_file")
    "${ffmpeg_cmd[@]}" 2>/dev/null &
    local ffmpeg_pid=$!

    local start_time=$(date +%s)
    while kill -0 "$ffmpeg_pid" 2>/dev/null; do
         if [ -f "$output_file" ]; then
             current_size=$(stat --format="%s" "$output_file" 2>/dev/null || echo 0)
         else
             current_size=0
         fi
         current_time=$(date +%s)
         elapsed=$(( current_time - start_time ))
         [ $elapsed -eq 0 ] && elapsed=1
         speed_kib=$(awk "BEGIN {printf \"%.0f\", ($current_size/1024)/$elapsed}")
         downloaded_mib=$(awk "BEGIN {printf \"%.2f\", $current_size/1024/1024}")
         if [ "$total_merge_bytes" -gt 0 ]; then
             percentage=$(awk "BEGIN {printf \"%.0f\", ($current_size/($total_merge_bytes))*100}")
             if [ "$speed_kib" -gt 0 ]; then
                 eta_sec=$(awk "BEGIN {printf \"%d\", (($total_merge_bytes - $current_size)/( $speed_kib*1024))}")
             else
                 eta_sec=0
             fi
             eta_formatted=$(printf "%02d:%02d" $((eta_sec/60)) $((eta_sec%60)))
         else
             percentage="?"
             total_merge_mib="?"
             eta_formatted="--:--"
         fi
         progress_line=$(printf "\e[32m[%s%%]\e[0m \e[33m%sMiB\e[0m of ~\e[36m%sMiB\e[0m \e[35m%sKiB/s\e[0m ETA \e[31m%s\e[0m" \
                             "$percentage" "$downloaded_mib" "$total_merge_mib" "$speed_kib" "$eta_formatted")
         printf "\r%s" "$progress_line"
         sleep 0.5
    done
    wait "$ffmpeg_pid"
    printf "\n"
}

########################################
# Main function
########################################
main() {
    print_banner
    print_prompt "Enter the manifest/playlist URL: "
    read manifest_url

    print_success "\nFetching available formats..."
    formats_output=$(yt-dlp --no-warnings -F "$manifest_url")

    # Extract audio and video lines.
    audio_lines=$(echo "$formats_output" | grep "audio_track")
    video_lines=$(echo "$formats_output" | grep -E '^[0-9]')

    audio_count=$(echo "$audio_lines" | wc -l)
    video_count=$(echo "$video_lines" | wc -l)

    if [ "$video_count" -eq 0 ]; then
        print_error "No video formats found."
        exit 1
    fi

    # Build a custom quality–choice table.
    # Use yt-dlp -F output; assume format: format_code, container, resolution, filesize, TBR, proto, etc.
    sorted_video=$(echo "$video_lines" | awk '{
        size=0; fs=""; tbr=""; proto="";
        for(i=1;i<=NF;i++){
            if($i ~ /^~/){
                fs=$i;
                s=fs; gsub(/~/,"",s); gsub(/MiB/,"",s); size=s+0;
            }
            if($i ~ /^[0-9]+k$/){
                tbr=$i;
            }
            if($i ~ /^(m3u8|mp4)$/){
                proto=$i;
            }
        }
        # Assume resolution is in field 3.
        print $1, $3, fs, tbr, proto, size;
    }' | sort -k6,6n)

    # Extract first three choices.
    choice1=$(echo "$sorted_video" | sed -n '1p')
    choice2=$(echo "$sorted_video" | sed -n '2p')
    choice3=$(echo "$sorted_video" | sed -n '3p')

    # Function to print one table row.
    print_row() {
        # Arguments: choice number, line data.
        local num="$1"
        local line="$2"
        local fmt res fs tbr proto numsize
        fmt=$(echo "$line" | awk '{print $1}')
        res=$(echo "$line" | awk '{print $2}')
        fs=$(echo "$line" | awk '{print $3}')
        tbr=$(echo "$line" | awk '{print $4}')
        proto=$(echo "$line" | awk '{print $5}')
        numsize=$(echo "$line" | awk '{print $6}')
        # Compute resolution label from resolution (e.g. "640x360" gives "360p")
        local height label
        height=$(echo "$res" | cut -d'x' -f2)
        label="${height}p"
        # Print row: choice number, label, resolution, FILESIZE, TBR, PROTO, with proper spacing.
        printf "\e[1;36m%s)%-7s %-10s │ %-14s %-8s %-8s|\e[0m\n" "$num" "$label" "$res" "$fs" "$tbr" "$proto"
    }

    echo ""
    # Display header based on whether separated audio exists.
    if [ "$audio_count" -gt 0 ] && [ "$audio_count" -eq "$video_count" ]; then
        echo -e "(have separated audio files)"
        balanced=1
    else
        echo -e "(doesn't have separated audio files)"
        balanced=0
    fi

    echo -e "Available quality choices:"
    echo -e "RESOLUTION           │ FILESIZE       TBR      PROTO   |"
    echo -e "───────────────────────────────────────────────────────"

    print_row 1 "$choice1"
    print_row 2 "$choice2"
    print_row 3 "$choice3"

    print_prompt "Select the desired quality (1/2/3): "
    read quality_choice

    case $quality_choice in
        1) chosen_line="$choice1" ;;
        2) chosen_line="$choice2" ;;
        3) chosen_line="$choice3" ;;
        *) print_error "Invalid selection." ; exit 1 ;;
    esac

    video_format_id=$(echo "$chosen_line" | awk '{print $1}')
    video_estimated_size=$(echo "$chosen_line" | awk '{print $6}')

    # For balanced mode, pick corresponding audio; else if audio exists, pick first.
    if [ "$balanced" -eq 1 ]; then
        audio_format_id=$(echo "$audio_lines" | sed -n "${quality_choice}p" | awk '{print $1}')
    else
        if [ "$audio_count" -gt 0 ]; then
            audio_format_id=$(echo "$audio_lines" | sed -n '1p' | awk '{print $1}')
        else
            audio_format_id=""
        fi
    fi

    print_success "\nFetching direct URLs for selected formats..."
    video_url=$(yt-dlp --no-warnings -f "$video_format_id" -g "$manifest_url")
    if [ -n "$audio_format_id" ]; then
        audio_url=$(yt-dlp --no-warnings -f "$audio_format_id" -g "$manifest_url")
    fi

    print_prompt "\nEnter the title for the output file (if it contains '/', that will be used as folder structure): "
    read input_title
    output_filepath=$(process_title "$input_title")

    temp_dir="$base_folder/.temp"
    create_directory_if_not_exists "$temp_dir" >&2
    temp_video="$temp_dir/temp_video.ts"
    temp_audio="$temp_dir/temp_audio.ts"

    echo ""
    download_file "$video_url" "$temp_video" "" "$video_format_id" "video" "$video_estimated_size"
    print_success "\nVideo downloaded successfully."

    if [ -n "$audio_url" ]; then
        echo ""
        download_file "$audio_url" "$temp_audio" "" "$audio_format_id" "audio" ""
        print_success "\nAudio downloaded successfully."

        echo ""
        print_prompt "Merging video and audio files...\n"
        merge_files "$temp_video" "$temp_audio" "$temp_dir/merged.mp4"

        mv "$temp_dir/merged.mp4" "$output_filepath"
        if [ $? -eq 0 ]; then
            print_success "\nFile saved to: $output_filepath"
        else
            print_error "\nFailed to move merged file."
        fi
    else
        mv "$temp_video" "$output_filepath"
        if [ $? -eq 0 ]; then
            print_success "\nFile saved to: $output_filepath"
        else
            print_error "\nFailed to move downloaded file."
        fi
    fi

    rm -f "$temp_video" "$temp_audio"
}

main
