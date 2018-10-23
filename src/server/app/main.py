from flask import Flask, request, json, jsonify
from flask_sqlalchemy import SQLAlchemy
from config import *

from datetime import datetime
import random

app = Flask(__name__)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://{}:{}@{}/{}'.format(DB_USER,DB_PASSWD,DB_HOST,MSG_DB_NAME)
app.config['SQLALCHEMY_BINDS'] = {'key_db': 'mysql+pymysql://{}:{}@{}/{}'.format(DB_USER,DB_PASSWD,DB_HOST,KEY_DB_NAME)}

db = SQLAlchemy(app)

class msg_db(db.Model):
    __tablename__ = 'messages'
    url_key = db.Column('url_key', db.String(5), primary_key=True)
    data = db.Column('data', db.String(3000))
    date_created = db.Column('date_created', db.DateTime, default=datetime.utcnow())

    def __init__(self, url_key, data):
        self.url_key = url_key
        self.data = data

class key_db(db.Model):
    __bind_key__ = 'key_db'
    __tablename__ = 'url_keys'
    id = db.Column('id', db.INTEGER, primary_key=True, autoincrement=True)
    url_key = db.Column('url_key', db.CHAR(5))
    used = db.Column('used', db.BOOLEAN)

db.create_all()

@app.route("/")
def main():
    return "Welcome to note-whisperer!"

@app.route("/post", methods=['POST'])
def post():
    if request.headers['Content-Type'] == 'application/json':
        req = request.json
        if "message" not in req:
            return not_valid(json.dumps(req))

        key_id = random.randint(1, 64^4)#64**5 - 64**4*2)
        query = key_db.query.filter_by(id=key_id, used=False).first()
        while not query and key_id > 0:
            key_id = random.randint(1, key_id)
            query = key_db.query.filter_by(id=key_id, used=False).first()

            if key_id == 1 and not query:
                query = key_db.query.filter_by(used=False).first()
                key_id = 0
        
        if not query:
            return internal_err()
        else:
            # mark key as used
            query.used = True
            db.session.commit()

        data = req['message']
        new_msg = msg_db(query.url_key, data)
        db.session.add(new_msg)
        db.session.commit()
        
        url = {'url': query.url_key}
        return jsonify(url)
    else:
        return not_supported(request.headers['Content-Type'])

@app.route("/read/<url>", methods=['GET'])
def read(url):
    query = msg_db.query.filter_by(url_key=url).first()
    if not query:
        return not_found()

    message = {'message': query.data}
    timestamp = query.date_created
    db.session.delete(query)
    db.session.commit()

    curr_time = datetime.utcnow()
    if (curr_time - timestamp).total_seconds() > 3600:
        return not_found()

    return jsonify(message)


@app.errorhandler(400)
def not_valid(error):
    message = {
        'status': 400,
        'message': 'Bad Request: ' + error,
    }
    resp = jsonify(message)
    resp.status_code = 400

    return resp

@app.errorhandler(404)
def not_found(error=None):
    message = {
        'status': 404,
        'message': 'Not Found',
    }
    resp = jsonify(message)
    resp.status_code = 404

    return resp

@app.errorhandler(415)
def not_supported(error):
    message = {
        'status': 415,
        'message': 'Unsupported Media Type: ' + error,
    }
    resp = jsonify(message)
    resp.status_code = 415

    return resp

@app.errorhandler(500)
def internal_err(error=None):
    message = {
        'status': 500,
        'message': 'Internal Server Error',
    }
    resp = jsonify(message)
    resp.status_code = 500

    return resp

if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=True, port=80)