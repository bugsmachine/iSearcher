from flask import Flask, request, send_file, jsonify
import requests
from io import BytesIO

app = Flask(__name__)


@app.route('/image', methods=['GET'])
def download_image():
    image_path = request.args.get('image_path')
    if not image_path:
        return jsonify({"error": "No image path provided"}), 400

    url = f"https://image.tmdb.org/t/p/w500/{image_path}"
    response = requests.get(url)

    if response.status_code == 200:
        img = BytesIO(response.content)
        return send_file(img, mimetype='image/jpeg', as_attachment=True, download_name='downloaded_image.jpg')
    else:
        return jsonify(
            {"error": f"Failed to download image. Status code: {response.status_code}"}), response.status_code


if __name__ == '__main__':
    app.run(debug=True)