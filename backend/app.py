import os
import random

from datetime import datetime
from pymongo import MongoClient
from bson.json_util import dumps

from flask.logging import default_handler
import logging


def get_is_cloud():
    return 'WEBSITE_INSTANCE_ID' in os.environ


# autopep8: off
### --- Initialize Application --- ###
is_cloud = get_is_cloud()
if is_cloud:
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor(
        connection_string=os.environ.get(
            'APPLICATIONINSIGHTS_CONNECTION_STRING', None),
        instrumentation_options={
            "flask": {"enabled": True},
            "azure_sdk": {"enabled": True},
            "django": {"enabled": False},
            "fastapi": {"enabled": False},
            "psycopg2": {"enabled": False},
            "requests": {"enabled": True},
            "urllib": {"enabled": True},
            "urllib3": {"enabled": True},   
        },
        logger_name=__name__,
    )
else:
    print("Running locally")

# Import Flask after running configure_azure_monitor()
from flask import Flask, json, request, jsonify
# autopep8: on
app = Flask(__name__)
app.logger.setLevel(logging.INFO)


# Setup MongoDB connection
db_connection_string = os.environ.get(
    'DB_CONNECTION_STRING', 'mongodb://root:example@localhost:27017/')
client = MongoClient(db_connection_string)
db = client['restaurants']  # Database name
restaurants_collection = db['restaurants']  # Collection name

# Possible attributes for random generation
styles = ["Italian", "Argentinian", "Moroccan",
          "Tunisian", "Polish", "American", "Chinese"]
names_prefix = ["The Golden", "The Rusty", "The Cozy",
                "The Spicy", "The Sweet", "The Savory"]
names_suffix = ["Duck", "Spoon", "House", "Place", "Corner", "Table"]
vegetarian = ["yes", "no"]
# ----------------------------------------------------------------------------


def generate_random_restaurant():
    name = f"{random.choice(names_prefix)} {random.choice(names_suffix)}"
    style = random.choice(styles)
    vegetarian = random.choice(["yes", "no"])
    # Opening hours between 9 AM and 11 AM
    open_hour = f"{random.randint(9, 11)}:00"
    # Closing hours between 8 PM and 11 PM
    close_hour = f"{random.randint(20, 23)}:00"

    return {
        "name": name,
        "style": style,
        "vegetarian": vegetarian,
        "open_hour": open_hour,
        "close_hour": close_hour
    }


@app.route('/restaurants/generate', methods=['POST'])
def generate_restaurants():
    num_restaurants = request.args.get('count', default=5, type=int)
    new_restaurants = [generate_random_restaurant()
                       for _ in range(num_restaurants)]
    result = restaurants_collection.insert_many(new_restaurants)
    return jsonify({"message": f"Successfully added {num_restaurants} restaurants.", "ids": [str(id) for id in result.inserted_ids]}), 201


# If the collection is empty (first time ever) - add restaurants
if restaurants_collection.count_documents({}) == 0:
    generate_restaurants()


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
        query['style'] = style.title()
    if vegetarian:
        query['vegetarian'] = vegetarian.lower()
    if open_now:
        query['open_hour'] = {"$lte": current_time}
        query['close_hour'] = {"$gte": current_time}

    recommendations = list(restaurants_collection.find(query))
    return dumps(recommendations)


@app.route('/version', methods=['GET'])
def version():
    version = os.environ.get('PACKAGE_VERSION', '1.0')
    return jsonify({"version": version})


@app.route('/health', methods=['GET'])
def healthcheck():
    # A basic check to ensure that the application is running
    # able to connect to the database and return data
    try:
        restaurants = list(restaurants_collection.find({}))
        # print("Connected to DB ")
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
        "/": {
            "GET": "Lists all available endpoints and their methods"
        },
        "/restaurants": {
            "GET": "Get all restaurants",
            "POST": "Add a new restaurant"
        },
        "/restaurants/<restaurant_id>": {
            "GET": "Get a restaurant by ID",
            "DELETE": "Delete a restaurant by ID"
        },
        "/restaurants/generate": {
            "POST": "Generate random restaurants into the database"
        },
        "/restaurants/recommendation": {
            "GET": "Get restaurant recommendations based on style, vegetarian, and open_now query parameters"
        },
        "/version": {
            "GET": "Get the current version of the application"
        },
        "/health": {
            "GET": "Perform a health check of the application"
        }
    })


@app.after_request
def log_request(response):
    if '/health' in request.path:
        return response

    headers = {key: value for key, value in request.headers}
    client_ip = request.headers.get(
        'Cf-Connecting-Ip', request.headers.get(
            'X-Forwarded-For', request.remote_addr)
    )

    log_params = {
        "method": request.method,
        "path": request.path,
        "ip": client_ip,
        "host": request.host,
        "params": json.dumps(request.args, default=str),
        "data": json.dumps(request.get_json(silent=True), default=str),
        "headers": headers
    }
    app.logger.info(json.dumps(log_params))

    return response


def main():
    app.run(host='0.0.0.0', port=os.environ.get('FLASK_PORT', 8000),
            debug=os.environ.get('FLASK_DEBUG', True))


if __name__ == '__main__':
    main()
