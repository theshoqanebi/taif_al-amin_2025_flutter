import os
import uuid

from flask import Flask, request, send_file, jsonify
from docx2pdf import convert

# Anchor everything to THIS file's folder, never the process CWD.
# When the Flutter app launches Python, the working directory is not the
# server folder, so relative paths ("uploads"/"outputs") land in the wrong
# place and Word's SaveAs writes the PDF somewhere /download never looks.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "outputs")

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({"message": "DOCX to PDF API with upload/download"})


def _convert_docx_to_pdf(input_path, output_path):
    """Run docx2pdf with COM initialized for the current (Flask worker) thread.

    Flask's dev server handles each request on a worker thread, and Word
    automation (win32com) needs COM initialized per thread. Without this the
    conversion can fail or behave unpredictably off the main thread.
    """
    try:
        import pythoncom  # provided by pywin32, a docx2pdf dependency on Windows
    except ImportError:
        pythoncom = None

    if pythoncom is not None:
        pythoncom.CoInitialize()
    try:
        convert(input_path, output_path)
    finally:
        if pythoncom is not None:
            pythoncom.CoUninitialize()


# Upload + convert
@app.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "Empty filename"}), 400

    if not file.filename.lower().endswith(".docx"):
        return jsonify({"error": "Only .docx files allowed"}), 400

    file_id = str(uuid.uuid4())

    # Absolute paths so Word's SaveAs writes exactly where we expect.
    input_path = os.path.abspath(os.path.join(UPLOAD_FOLDER, f"{file_id}.docx"))
    output_path = os.path.abspath(os.path.join(OUTPUT_FOLDER, f"{file_id}.pdf"))

    file.save(input_path)

    try:
        _convert_docx_to_pdf(input_path, output_path)
    except Exception as e:
        return jsonify({"error": f"Conversion failed: {e}"}), 500
    finally:
        # remove the original docx
        if os.path.exists(input_path):
            os.remove(input_path)

    # docx2pdf can report success while writing nothing (e.g. Word produced the
    # file elsewhere). Verify here so the client gets a clear error instead of a
    # later 500 from /download.
    if not os.path.exists(output_path):
        return jsonify({
            "error": "Conversion reported success but no PDF was produced.",
            "expected_path": output_path,
        }), 500

    return jsonify({
        "message": "File uploaded and converted",
        "file_id": file_id,
        "download_url": f"/download/{file_id}",
    })


# Download PDF
@app.route("/download/<file_id>", methods=["GET"])
def download(file_id):
    # Guard against path traversal: keep only the bare id, no separators.
    safe_id = os.path.basename(file_id)
    file_path = os.path.abspath(os.path.join(OUTPUT_FOLDER, f"{safe_id}.pdf"))

    # Ensure the resolved path is still inside OUTPUT_FOLDER.
    if os.path.commonpath([file_path, OUTPUT_FOLDER]) != OUTPUT_FOLDER:
        return jsonify({"error": "Invalid file id"}), 400

    if not os.path.exists(file_path):
        return jsonify({"error": "File not found"}), 404

    return send_file(
        file_path,
        as_attachment=True,
        download_name=f"{safe_id}.pdf",
        mimetype="application/pdf",
    )


if __name__ == "__main__":
    # use_reloader=False: the debug reloader restarts/duplicates the process and
    # can break when the script is launched as a bundled asset. Keep a single,
    # stable process for the Flutter app to talk to.
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)