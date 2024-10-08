from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

# Sample data to represent traffic light states
traffic_lights = {
    "junction_1": {"status": "green", "time_left": 30},
    "junction_2": {"status": "red", "time_left": 45},
    "junction_3": {"status": "yellow", "time_left": 10},
}

@app.route('/traffic_light/<junction_id>', methods=['GET'])
def get_traffic_light_status(junction_id):
    if junction_id in traffic_lights:
        return jsonify(traffic_lights[junction_id])
    else:
        return jsonify({"error": "Junction not found"}), 404

@app.route('/update_traffic_light', methods=['POST'])
def update_traffic_light_status():
    data = request.json
    junction_id = data.get('junction_id')
    status = data.get('status')
    time_left = data.get('time_left')

    if junction_id and status and time_left:
        traffic_lights[junction_id] = {"status": status, "time_left": time_left}
        return jsonify({"message": "Traffic light updated successfully"}), 200
    else:
        return jsonify({"error": "Invalid data"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

#Server
#http://172.23.39.233:5000/traffic_light/junction_1
#// real-time, synconised traffic light (should talk to each other but not show the same traffic light (need to open 2 UI and demo that))