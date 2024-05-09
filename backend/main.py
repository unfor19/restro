import os

from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)

# Dummy database simulation
restaurants = {
    1: {'name': 'Pasta Paradise', 'address': '123 Spaghetti Lane', 'style': 'Italian', 'vegetarian': 'no', 'open_hour': '10:00', 'close_hour': '22:00', 'deliveries': 'yes'},
    2: {'name': 'Seoul Food', 'address': '789 Kimchi Blvd', 'style': 'Korean', 'vegetarian': 'yes', 'open_hour': '11:00', 'close_hour': '23:00', 'deliveries': 'no'},
    3: {'name': 'French Fries', 'address': '456 Baguette St', 'style': 'French', 'vegetarian': 'no', 'open_hour': '12:00', 'close_hour': '21:00', 'deliveries': 'yes'}
}
# History storage
request_history = []


@app.route('/restaurants', methods=['GET', 'POST'])
def handle_restaurants():
    if request.method == 'GET':
        return jsonify(list(restaurants.values()))
    elif request.method == 'POST':
        data = request.get_json()
        new_id = max(restaurants.keys()) + 1
        restaurants[new_id] = data
        return jsonify({"id": new_id, "message": "Restaurant added"}), 201


@app.route('/restaurants/<int:restaurant_id>', methods=['GET', 'DELETE'])
def handle_restaurant(restaurant_id):
    if request.method == 'GET':
        return jsonify(restaurants.get(restaurant_id, 'Restaurant not found'))
    elif request.method == 'DELETE':
        if restaurant_id in restaurants:
            del restaurants[restaurant_id]
            return jsonify({"message": "Restaurant deleted"})
        else:
            return jsonify({"error": "Restaurant not found"}), 404


@app.route('/restaurants/recommendation', methods=['GET'])
def recommend_restaurant():
    style = request.args.get('style', None)
    vegetarian = request.args.get('vegetarian', None)
    open_now = request.args.get('open_now', None)
    current_time = datetime.now().strftime("%H:%M")

    recommendations = [
        r for r in restaurants.values()
        if (style is None or r['style'] == style) and
           (vegetarian is None or r['vegetarian'] == vegetarian) and
           (open_now is None or (r['open_hour']
            <= current_time <= r['close_hour']))
    ]

    return jsonify({"recommendations": recommendations})


@app.route('/restaurants/<int:restaurant_id>/history', methods=['GET'])
def restaurant_history(restaurant_id):
    filtered_history = [
        h for h in request_history if h['restaurant_id'] == restaurant_id]
    return jsonify(filtered_history)


@app.route('/restaurants/history', methods=['GET'])
def all_history():
    return jsonify(request_history)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=os.environ.get('FLASK_PORT', 8000),
            debug=os.environ.get('FLASK_DEBUG', True))
