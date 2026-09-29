ffmpeg -y -f lavfi -i "sine=frequency=444:duration=1:sample_rate=22050" -ac 1 -c:a libmp3lame -b:a 32k first.flv
ffmpeg -y -f lavfi -i "sine=frequency=444:duration=2:sample_rate=22050" -ac 1 -c:a libmp3lame -b:a 16k second.flv
