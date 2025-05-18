from flask import Flask, request, jsonify
from TTS.api import TTS
import tempfile
import os

app = Flask(__name__)

tts = TTS(model_name="tts_models/pl/mai_female/vits", progress_bar=False, gpu=False)
# tts = TTS("tts_models/multilingual/multi-dataset/your_tts", gpu=False)

@app.route("/speak", methods=["POST"])
def speak():
    text = request.form.get("text", "")
    if not text:
        return jsonify({"error": "Brak tekstu"}), 400

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tts.tts_to_file(
            text=text, 
            file_path=f.name,
            speed=0.8
        )
        wav_data = open(f.name, "rb").read()
        os.unlink(f.name)

    return (
        wav_data,
        200,
        {
            "Content-Type": "audio/wav",
            "Content-Disposition": "inline; filename=output.wav"
        }
    )

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=5002)
