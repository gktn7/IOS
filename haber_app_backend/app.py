from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from flask_cors import CORS
import datetime

app = Flask(__name__)
CORS(app) 

app.config["MONGO_URI"] = "mongodb://localhost:27017/haber_app"
mongo = PyMongo(app)

history_collection = mongo.db.history

# Haber kaydetme endpoint
@app.route("/save_history", methods=["POST"])
def save_history():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400

    data['saved_at'] = datetime.datetime.utcnow()

    try:
        history_collection.insert_one(data)
        return jsonify({"message": "Haber kaydedildi"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Tüm geçmişi getirme endpoint
@app.route("/history", methods=["GET"])
def get_history():
    try:
        history = list(history_collection.find().sort("saved_at", -1))
        for h in history:
            h["_id"] = str(h["_id"]) 
        return jsonify(history), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=5000)

