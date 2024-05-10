import os
from flask import Flask, request, jsonify
from datetime import datetime
from pymongo import MongoClient
from bson.json_util import dumps

app = Flask(__name__)

# Setup MongoDB connection
db_connection_string = os.environ.get(
    'DB_CONNECTION_STRING', 'mongodb://root:example@localhost:27017/')
client = MongoClient(db_connection_string)
db = client['restaurants']  # Database name
restaurants_collection = db['restaurants']  # Collection name


@app.route('/restaurants', methods=['GET', 'POST'])
def handle_restaurants():
    if request.method == 'GET':
        restaurants = list(restaurants_collection.find({}))
        return dumps(restaurants)  # Use dumps to convert MongoDB BSON to JSON
    elif request.method == 'POST':
        data = request.get_json()
        result = restaurants_collection.insert_one(data)
        return jsonify({"id": str(result.inserted_id), "message": "Restaurant added"}), 201


@app.route('/restaurants/<int:restaurant_id>', methods=['GET', 'DELETE'])
def handle_restaurant(restaurant_id):
    if request.method == 'GET':
        restaurant = restaurants_collection.find_one({"_id": restaurant_id})
        if restaurant:
            return dumps(restaurant)
        else:
            return jsonify({"error": "Restaurant not found"}), 404
    elif request.method == 'DELETE':
        result = restaurants_collection.delete_one({"_id": restaurant_id})
        if result.deleted_count > 0:
            return jsonify({"message": "Restaurant deleted"})
        else:
            return jsonify({"error": "Restaurant not found"}), 404


@app.route('/restaurants/recommendation', methods=['GET'])
def recommend_restaurant():
    style = request.args.get('style', None)
    vegetarian = request.args.get('vegetarian', None)
    open_now = request.args.get('open_now', None)
    current_time = datetime.now().strftime("%H:%M")
    query = {}
    if style:
        query['style'] = style.lower()
    if vegetarian:
        query['vegetarian'] = vegetarian.lower()
    if open_now:
        query['open_hour'] = {"$lte": current_time}
        query['close_hour'] = {"$gte": current_time}

    recommendations = list(restaurants_collection.find(query))
    return dumps(recommendations)


@app.route('/version', methods=['GET'])
def version():
    with open('version') as version_file:
        version = version_file.read().strip()
    return jsonify({"version": version})


@app.route('/health', methods=['GET'])
def healthcheck():
    # A basic check to ensure that the application is running
    # able to connect to the database and return data
    try:
        restaurants = list(restaurants_collection.find({}))
        print("Connected to DB ")
        if len(restaurants) > 0:
            return jsonify({"message": "OK"}), 200
        else:
            print(restaurants)
            return jsonify({"error": "No data in database"}), 500
    except Exception as e:
        error_msg = f"Error: {str(e)}"
        print(error_msg)
        return jsonify({"error": f"Internal Server Error"}), 500


@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "/restaurants": {
            "GET": "Get all restaurants",
            "POST": "Add a new restaurant"
        },
        "/restaurants/<restaurant_id>": {
            "GET": "Get a restaurant by ID",
            "DELETE": "Delete a restaurant by ID"
        },
        "/restaurants/recommendation": {
            "GET": "Get restaurant recommendations based on query params"
        },
        "/restaurants/<restaurant_id>/history": {
            "GET": "Get history of requests made to a restaurant by ID"
        },
        "/restaurants/history": {
            "GET": "Get history of all requests made to all restaurants"
        },
        "/version": {
            "GET": "Get the version of the application"
        },
        "/health": {
            "GET": "Health check endpoint"
        }
    })


def main():
    app.run(host='0.0.0.0', port=os.environ.get('FLASK_PORT', 8000),
            debug=os.environ.get('FLASK_DEBUG', True))


if __name__ == '__main__':
    main()
