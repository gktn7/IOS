from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from flasgger import Swagger 
import datetime

app = Flask(__name__)
CORS(app)

swagger = Swagger(app)

app.config["MONGO_URI"] = "mongodb://localhost:27017/haber_app"
mongo = PyMongo(app)

history_collection = mongo.db.history
users_collection = mongo.db.users
comments_collection = mongo.db.comments
likes_collection = mongo.db.likes

@app.route("/register", methods=["POST"])
def register():
    """
    Kullanıcı Kayıt İşlemi
    ---
    tags:
      - Auth
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            email:
              type: string
              example: kullanıcı@mail.com
            password:
              type: string
              example: 123456
    responses:
      201:
        description: Kullanıcı başarıyla oluşturuldu
      400:
        description: Eksik bilgi veya zaten kayıtlı e-posta
    """
    data = request.json
    email = data.get('email')
    password = str(data.get('password', ''))

    if not email or not password:
        return jsonify({"error": "Email ve şifre gerekli"}), 400

    if users_collection.find_one({"email": email}):
        return jsonify({"error": "Bu email zaten kayıtlı"}), 400

    hashed_password = generate_password_hash(password)
    user_data = {
        "email": email,
        "password": hashed_password,
        "created_at": datetime.datetime.utcnow()
    }

    try:
        users_collection.insert_one(user_data)
        return jsonify({"message": "Kullanıcı başarıyla oluşturuldu"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/login", methods=["POST"])
def login():
    """
    Kullanıcı Giriş İşlemi
    ---
    tags:
      - Auth
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            email:
              type: string
            password:
              type: string
    responses:
      200:
        description: Giriş başarılı
      401:
        description: Hatalı email veya şifre
    """
    data = request.json
    email = data.get('email')
    password = str(data.get('password', ''))

    user = users_collection.find_one({"email": email})

    if user and check_password_hash(user['password'], password):
        return jsonify({
            "message": "Giriş başarılı",
            "user_id": str(user['_id']),
            "email": user['email']
        }), 200
    else:
        return jsonify({"error": "Hatalı email veya şifre"}), 401

@app.route("/save_history", methods=["POST"])
def save_history():
    """
    Haber Geçmişine Kaydetme
    ---
    tags:
      - History
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            title:
              type: string
            url:
              type: string
    responses:
      201:
        description: Haber kaydedildi
    """
    data = request.json
    data['saved_at'] = datetime.datetime.utcnow()
    try:
        history_collection.insert_one(data)
        return jsonify({"message": "Haber kaydedildi"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/history", methods=["GET"])
def get_history():
    """
    Haber Geçmişini Listeleme
    ---
    tags:
      - History
    responses:
      200:
        description: Geçmiş listesi başarıyla getirildi
    """
    try:
        history = list(history_collection.find().sort("saved_at", -1))
        for h in history:
            h["_id"] = str(h["_id"]) 
        return jsonify(history), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/comments", methods=["POST"])
def add_comment():
    """
    Habere Yorum Ekleme
    ---
    tags:
      - Comments
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            news_url:
              type: string
              description: Haberin URL'si veya benzersiz ID'si
            user_email:
              type: string
            comment_text:
              type: string
    responses:
      201:
        description: Yorum başarıyla eklendi
      400:
        description: Eksik bilgi
    """
    data = request.json
    news_url = data.get('news_url')
    user_email = data.get('user_email')
    comment_text = data.get('comment_text')

    if not news_url or not user_email or not comment_text:
        return jsonify({"error": "news_url, user_email ve comment_text gerekli"}), 400

    comment_data = {
        "news_url": news_url,
        "user_email": user_email,
        "comment_text": comment_text,
        "like_count": 0,
        "created_at": datetime.datetime.utcnow()
    }

    try:
        result = comments_collection.insert_one(comment_data)
        return jsonify({
            "message": "Yorum eklendi",
            "comment_id": str(result.inserted_id)
        }), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/comments", methods=["GET"])
def get_comments():
    """
    Haberin Yorumlarını Getir
    ---
    tags:
      - Comments
    parameters:
      - name: news_url
        in: query
        type: string
        required: true
        description: Haberin URL'si
    responses:
      200:
        description: Yorumlar listesi
    """
    news_url = request.args.get('news_url')
    
    if not news_url:
        return jsonify({"error": "news_url parametresi gerekli"}), 400

    try:
        comments = list(comments_collection.find({"news_url": news_url}).sort("created_at", -1))
        for c in comments:
            c["_id"] = str(c["_id"])
            c["created_at"] = c["created_at"].isoformat() if c.get("created_at") else None
        return jsonify(comments), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/comments/like", methods=["POST"])
def like_comment():
    """
    Yorum Beğenme
    ---
    tags:
      - Comments
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            comment_id:
              type: string
    responses:
      200:
        description: Beğeni eklendi
      404:
        description: Yorum bulunamadı
    """
    from bson.objectid import ObjectId
    
    data = request.json
    comment_id = data.get('comment_id')

    if not comment_id:
        return jsonify({"error": "comment_id gerekli"}), 400

    try:
        result = comments_collection.update_one(
            {"_id": ObjectId(comment_id)},
            {"$inc": {"like_count": 1}}
        )
        if result.modified_count == 0:
            return jsonify({"error": "Yorum bulunamadı"}), 404
        return jsonify({"message": "Beğeni eklendi"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/profile", methods=["GET"])
def get_profile():
    """
    Kullanıcı Profil Bilgileri
    ---
    tags:
      - Profile
    parameters:
      - name: email
        in: query
        type: string
        required: true
    responses:
      200:
        description: Profil bilgileri
    """
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "email parametresi gerekli"}), 400

    try:
        user = users_collection.find_one({"email": email})
        if not user:
            return jsonify({"error": "Kullanıcı bulunamadı"}), 404

        comment_count = comments_collection.count_documents({"user_email": email})
        
        total_likes = 0
        user_comments = comments_collection.find({"user_email": email})
        for c in user_comments:
            total_likes += c.get("like_count", 0)

        history_count = history_collection.count_documents({})

        profile_data = {
            "email": user["email"],
            "created_at": user.get("created_at").isoformat() if user.get("created_at") else None,
            "stats": {
                "comment_count": comment_count,
                "total_likes": total_likes,
                "history_count": history_count
            }
        }

        return jsonify(profile_data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/user/comments", methods=["GET"])
def get_user_comments():
    """
    Kullanıcının Yorumları
    ---
    tags:
      - Profile
    parameters:
      - name: email
        in: query
        type: string
        required: true
    responses:
      200:
        description: Kullanıcının yorumları
    """
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "email parametresi gerekli"}), 400

    try:
        comments = list(comments_collection.find({"user_email": email}).sort("created_at", -1))
        for c in comments:
            c["_id"] = str(c["_id"])
            c["created_at"] = c["created_at"].isoformat() if c.get("created_at") else None
        return jsonify(comments), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/likes", methods=["POST"])
def toggle_like():
    """
    Haber Beğen/Beğenmekten Vazgeç (Toggle)
    ---
    tags:
      - Likes
    parameters:
      - name: body
        in: body
        required: true
        schema:
          properties:
            email:
              type: string
            news_url:
              type: string
            news_title:
              type: string
            news_image:
              type: string
    responses:
      200:
        description: Beğeni durumu değiştirildi
    """
    data = request.json
    email = data.get('email')
    news_url = data.get('news_url')
    news_title = data.get('news_title')
    news_image = data.get('news_image')

    if not email or not news_url:
        return jsonify({"error": "email ve news_url gerekli"}), 400

    try:
        existing = likes_collection.find_one({"email": email, "news_url": news_url})
        
        if existing:
            likes_collection.delete_one({"_id": existing["_id"]})
            return jsonify({"message": "Beğeni kaldırıldı", "liked": False}), 200
        else:
            likes_collection.insert_one({
                "email": email,
                "news_url": news_url,
                "news_title": news_title,
                "news_image": news_image,
                "created_at": datetime.datetime.utcnow()
            })
            return jsonify({"message": "Beğenildi", "liked": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/likes", methods=["GET"])
def get_user_likes():
    """
    Kullanıcının Beğendiği Haberler
    ---
    tags:
      - Likes
    parameters:
      - name: email
        in: query
        type: string
        required: true
    responses:
      200:
        description: Beğenilen haberler listesi
    """
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "email parametresi gerekli"}), 400

    try:
        likes = list(likes_collection.find({"email": email}).sort("created_at", -1))
        for l in likes:
            l["_id"] = str(l["_id"])
            l["created_at"] = l["created_at"].isoformat() if l.get("created_at") else None
        return jsonify(likes), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/likes/check", methods=["GET"])
def check_like():
    """
    Haber Beğenildi mi Kontrol
    ---
    tags:
      - Likes
    parameters:
      - name: email
        in: query
        type: string
        required: true
      - name: news_url
        in: query
        type: string
        required: true
    responses:
      200:
        description: Beğeni durumu
    """
    email = request.args.get('email')
    news_url = request.args.get('news_url')
    
    if not email or not news_url:
        return jsonify({"error": "email ve news_url parametreleri gerekli"}), 400

    try:
        existing = likes_collection.find_one({"email": email, "news_url": news_url})
        return jsonify({"liked": existing is not None}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, port=5000)
