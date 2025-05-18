from flask import Flask, request, jsonify
import subprocess
import tempfile
import os

app = Flask(__name__)

MODEL_PATH = "models/ggml-tiny.bin"
WHISPER_BIN = "/app/whisper.cpp/build/bin/whisper-cli"
LANGUAGE = "pl"

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'audio_file' not in request.files:
        return jsonify({"error": "Missing audio_file"}), 400

    audio_file = request.files['audio_file']

    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp_audio:
        audio_file.save(tmp_audio.name)
        # Uruchom whisper.cpp na tym pliku
        cmd = [
            WHISPER_BIN, 
            "-m", MODEL_PATH, 
            "-f", tmp_audio.name, 
            "-l", LANGUAGE,
            "--output-file", "-",
            "--output-txt"
            ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

            if result.returncode != 0:
                return jsonify({"error": "Whisper failed", "details": result.stderr})

            transcription = result.stdout.strip()
            return jsonify({"transcription": transcription})

        except subprocess.TimeoutExpired:
            return jsonify({"error": "Whisper timed out"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
