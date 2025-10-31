import logging
from flask import Flask, request, jsonify

# Initialize Flask App
app = Flask(__name__)

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

api_data = {
    "products": [
        {"id": 1, "name": "Laptop", "price": 1200},
        {"id": 2, "name": "Keyboard", "price": 75},
        {"id": 3, "name": "Mouse", "price": 25}
    ]
}

logging.info("API configuration loaded directly from app.py")

# --- Global Error Handlers ---
@app.errorhandler(404)
def not_found_error(error):
    logging.warning(f"404 Not Found: {request.path}")
    return jsonify({"status": "Error", "message": "Resource not found."}), 404

@app.errorhandler(500)
def internal_error(error):
    # Log the actual exception for debugging purposes
    logging.exception("An internal server error occurred.")
    return jsonify({"status": "Error", "message": "An internal server error occurred."}), 500
# --- End Global Error Handlers ---

@app.route('/')
def index():
    """
    Simple status endpoint to confirm the API is running.
    """
    logging.info("Root status endpoint was hit.")
    return jsonify({
        "status": "Success",
        "message": "API service is running.",
        "endpoints": {
            "GET /": "This status page.",
            "GET /api/health": "A simple health check endpoint.",
            "GET, POST /api/echo": "Echoes back request details.",
            "GET /api/products": "Returns a static list of products."
        }
    }), 200

@app.route('/api/health', methods=['GET'])
def health_check():
    """A simple health check endpoint that returns a greeting."""
    logging.info("Health check endpoint was hit.")
    return jsonify({"status": "Success", "message": "API is healthy and running."}), 200

@app.route('/api/echo', methods=['GET', 'POST'])
def echo():
    """Echoes back the request method, headers, and body."""
    logging.info(f"Echo endpoint was hit with method {request.method}.")
    response_data = {
        "method": request.method,
        "path": request.path,
        "query_params": dict(request.args),
        "headers": dict(request.headers)
    }
    if request.is_json:
        try:
            response_data["json_body"] = request.get_json()
        except Exception as e:
            response_data["json_body_error"] = str(e)
    elif request.data:
        response_data["raw_data"] = request.data.decode('utf-8', errors='ignore')

    return jsonify(response_data), 200

@app.route('/api/products', methods=['GET'])
def get_products():
    """Returns a static list of products."""
    logging.info("Products endpoint was hit.")
    return jsonify(api_data.get("products", [])), 200

if __name__ == '__main__':
    # For local development testing
    # In Azure App Service, Gunicorn will be used to run the app.
    app.run(debug=True, port=8080)