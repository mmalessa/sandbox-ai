# My AI Sandbox

## STT
```shell
/app/whisper.cpp/build/bin/whisper-cli \
    -m models/ggml-tiny.bin \
    -f test.wav \
    -l pl \
    --output-file -
    --output-txt
```

## TTS
```shell
tts --list_models
tts --text "Witaj świecie!" --model_name tts_models/pl/mai_female/glow-tts --out_path output.wav
```