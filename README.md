# Stream Hunter

Stream Hunter is a Bash script designed to download video and audio streams from `shikho.com` manifest or playlist URLs using `yt-dlp` and `ffmpeg`. It provides a user-friendly interface with colored output and progress bars for both video and audio downloads. The script also merges the downloaded video and audio files into a single `.mp4` file if the link have separated audio files.

## Features
- **Download videos directly**: If the video file doesn't have any separated audio files and it's already merged, it'll download the video without any conflict.
- **Download Video and Audio**: Downloads video and audio streams separately if the audio file is separated and not merged.
- **Progress Bars**: Displays real-time progress bars for video and audio downloads.
- **Quality Selection**: Allows users to choose from low, mid, or high-quality streams.
- **Automatic Merging**: Merges downloaded video and audio files into a single `.mp4` file.
- **Custom Output Path**: Supports custom folder structures for saving files.

## Prerequisites

Before using Stream Hunter, ensure you have the following tools installed:

1. **`yt-dlp`**: A powerful command-line tool for downloading videos from various platforms.
   - Installation: `pip install yt-dlp`
2. **`ffmpeg`**: A multimedia framework for handling video and audio streams.
   - Installation: `sudo apt install ffmpeg` (on Ubuntu/Debian) or download from [ffmpeg.org](https://ffmpeg.org/download.html).

## Usage

**requirements**:
   ```bash
   apt install ffmpeg
   pip install yt-dlp
   ```
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/stream-hunter.git
   cd stream-hunter
   ```

2. **Make the Script Executable**:
   ```bash
   chmod +x bash.sh
   ```

3. **Run the Script**:
   ```bash
   ./bash.sh
   ```

4. **Follow the Prompts**:
   - Enter the `.m3u8` manifest URL when prompted.
   - Select the desired quality .
   - Enter the title for the output file. Use `/` to create subfolders (e.g., `folder_name/file_name`).

5. **Output**:
   - The script will download the video and audio streams, merge them, and save the final file in the specified location.

## Example

```bash
$ ./bash.sh
--------------------------------------------
           Stream Hunter
--------------------------------------------
Enter the URL: https://example.com/manifest.m3u8

Fetching available formats...
Available quality choices:
1) Low  - 640x360 + audio_track_128
2) Mid  - 1280x720 + audio_track_256
3) Best - 1920x1080 + audio_track_320

Select the desired quality (1/2/3): 2

Fetching direct URLs for selected formats...

Enter the title for the output file (if it contains '/', that will be used as folder structure): my_videos/video1

Downloading video - 1280x720
[99%] 135.25MiB of ~137.02MiB 1847KiB/s ETA 00:00
Video downloaded successfully.

Downloading audio - audio_track_256
[Audio] 12.34MiB downloaded
Audio downloaded successfully.

Merging video and audio files...
File saved to: /storage/emulated/0/Stream Videos/my_videos/video1.mp4
```

## Configuration

- **Base Folder**: The default folder for saving files is `/storage/emulated/0/Stream Videos`. You can modify the `base_folder` variable in the script to change this location.
- **Temporary Files**: Temporary files are stored in a `.temp` folder inside the base folder and are automatically deleted after the merge is complete.

## Notes

- Ensure you have a stable internet connection while downloading streams.
- The script assumes that the `.m3u8` manifest contains both video and audio streams.
- If the audio file size is unavailable, the progress bar will only show the downloaded MiB without percentage or ETA.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
