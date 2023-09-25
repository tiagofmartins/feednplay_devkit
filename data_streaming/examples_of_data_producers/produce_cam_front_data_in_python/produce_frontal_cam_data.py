import argparse
import math
import os
import time
import json
import confluent_kafka
import cv2 as cv
import numpy as np

# --------------------------------------------------
# Examples of command lines to run this script

# python3 top_camera.py --sample top_cam_sample.mp4 --preview
# python3 top_camera.py --cam_index 0 --cam_width 1280 --cam_height 720 --preview

# --------------------------------------------------
# Class to mediate the data production

class FnpDataProducer:
    topics_to_produce = {}
    topics_currently_subscribed = []
    time_last_check_topics_subscribed = 0
    time_start = time.time()
    
    def __init__(self, topics_preffix='', callback=True):
        self.topics_preffix = topics_preffix
        self.kafka_producer = confluent_kafka.Producer({'bootstrap.servers': 'localhost:9092', 'message.max.bytes': 25165824})
        self.callback_func = self.__delivery_callback if callback else None
    
    def need_to_produce_topic(self, topic):
        if time.time() - self.time_last_check_topics_subscribed > 5:
           self.time_last_check_topics_subscribed = time.time()
           self.topics_currently_subscribed = [] # TODO get list of topics that were recently subscribed (last n seconds)
        # return self.__add_preffix(topic) in self.topics_currently_subscribed
        return True # TODO remove this line and uncomment the previous one
    
    def set_value_bytes(self, topic, value):
        assert type(value) is bytes
        self.topics_to_produce[topic] = value
    
    def set_value_dict(self, topic, value):
        assert type(value) is dict
        value_bytes = json.dumps(value).encode('utf-8')
        self.set_value_bytes(topic, value_bytes)
    
    def send_values(self):
        for topic, value in self.topics_to_produce.items():
            self.kafka_producer.produce(self.__add_preffix(topic), value, callback=self.callback_func)
        self.kafka_producer.flush()
        self.topics_to_produce.clear()
    
    def __delivery_callback(self, err, msg):
        timestamp = format(time.time() - self.time_start, '.3f')
        if err is not None:
            print('[{}] Error: {}'.format(timestamp, err))
        else:
            message = '[{}] {}: '.format(timestamp, msg.topic())
            if '_rgb_' in msg.topic() or '_grayscale_' in msg.topic():
                message += 'image'
            else:
                message += msg.value().decode('utf-8')
            print(message)
    
    def __add_preffix(self, topic):
        return self.topics_preffix + topic

# --------------------------------------------------
# Constants

# --------------------------------------------------
# Variables

curr_dir = os.path.dirname(os.path.abspath(__file__))
producer = FnpDataProducer(topics_preffix='cam1_', callback=False)
face_cascade = cv.CascadeClassifier(os.path.join(curr_dir, 'haarcascade_frontalface_default.xml'))
previous_frame = None

# --------------------------------------------------
# Parse input arguments

parser = argparse.ArgumentParser()
parser.add_argument("--sample", type=str, help="Path of sample video.")
parser.add_argument("--cam_index", type=int, help="Camera index.")
parser.add_argument("--cam_width", type=int, help="Camera image width.")
parser.add_argument("--cam_height", type=int, help="Camera image height.")
parser.add_argument('--preview', action=argparse.BooleanOptionalAction, help="Pass true to launch preview windows.")
args = parser.parse_args()
assert args.sample is not None or args.cam_index is not None
if args.sample is not None:
    assert os.path.isfile(args.sample)
else:
    assert args.cam_width is not None and args.cam_height is not None

# --------------------------------------------------
# Create opencv capture

if args.sample:
    capture = cv.VideoCapture(args.sample)
else:
    capture = cv.VideoCapture(args.cam_index)
    capture.set(cv.CAP_PROP_FRAME_WIDTH, args.cam_width)
    capture.set(cv.CAP_PROP_FRAME_HEIGHT, args.cam_height)

# --------------------------------------------------
# Start capturing

print('Capture started')
try:
    while capture.isOpened():

        # --------------------------------------------------
        # Read new video frame

        ret, frame = capture.read()
        if not ret:
            if args.sample:
                capture.set(cv.CAP_PROP_POS_FRAMES, 0)
            print('Ignoring empty frame')
            continue
        
        # --------------------------------------------------
        # Flip frame horizontally

        frame = cv.flip(frame, 1)
        frame_debug = frame.copy()
        
        # --------------------------------------------------
        # Produce frame images

        full_res = min(frame.shape[0], 1080)
        resolutions = {'full': full_res, 'half': int(full_res / 2), 'quarter': int(full_res / 4)}
        for res in resolutions:
            topic_rgb = "frame_rgb_{}".format(res)
            topic_gray = "frame_grayscale_{}".format(res)
            rgb_required = producer.need_to_produce_topic(topic_rgb)
            gray_required = producer.need_to_produce_topic(topic_gray)
            if rgb_required or gray_required:
                if frame.shape[0] != resolutions[res]:
                    w = int(frame.shape[1] * (resolutions[res] / float(frame.shape[0])))
                    image_rgb = cv.resize(frame, (w, resolutions[res]), interpolation=cv.INTER_AREA)
                else:
                    image_rgb = frame
                if rgb_required:
                    producer.set_value_bytes(topic_rgb, cv.imencode('.jpg', image_rgb)[1].tobytes())
                if gray_required:
                    image_gray = cv.cvtColor(image_rgb, cv.COLOR_BGR2GRAY)
                    producer.set_value_bytes(topic_gray, cv.imencode('.jpg', image_gray)[1].tobytes())
        
        # --------------------------------------------------
        # Frame difference

        # diff_needed = False
        # frame_diff = None
        # matrix_num_cols_options = (360, 90)
        # for cols in matrix_num_cols_options:
        #     topic = 'frame_diff_{}cols'.format(cols)
        #     if producer.need_to_produce_topic(topic):
        #         diff_needed = True
        #         if previous_frame is None:
        #             break
        #         if frame_diff is None:
        #             frame_diff = cv.absdiff(frame, previous_frame)
        #             frame_diff = cv.cvtColor(frame_diff, cv.COLOR_BGR2GRAY)
        #         rows = int(frame_diff.shape[0] * (cols / frame_diff.shape[1]))
        #         frame_diff_resized = cv.resize(frame_diff, (cols, rows), interpolation=cv.INTER_AREA)
        #         frame_diff_matrix = np.asarray(frame_diff_resized).tolist()
        #         frame_diff_json = {'w': cols, 'h': rows, 'matrix': frame_diff_matrix}
        #         producer.set_value_dict(topic, frame_diff_json)
        # if diff_needed:
        #     previous_frame = frame.copy()
        
        # --------------------------------------------------
        # Face detection

        if producer.need_to_produce_topic('face_detections'):
            face_detections_json = {'detections': []}
            frame_gray = cv.cvtColor(frame, cv.COLOR_BGR2GRAY)
            faces, _, level_weights = face_cascade.detectMultiScale3(frame_gray, scaleFactor=1.025, minNeighbors=40, outputRejectLevels=True)
            for i, (x, y, w, h) in enumerate(faces):
                x_rel = x / float(frame_gray.shape[1])
                y_rel = y / float(frame_gray.shape[0])
                w_rel = w / float(frame_gray.shape[1])
                h_rel = h / float(frame_gray.shape[0])
                if h_rel < 0.075:
                    continue
                if level_weights[i] < 0.2:
                    continue
                face_detections_json['detections'].append({'x': x_rel, 'y': y_rel, 'w': w_rel, 'h': h_rel, 'confidance': level_weights[i]})
                if frame_debug is not None:
                    cv.rectangle(frame_debug, (x, y), (x + w, y + h), (255, 0, 0), 1)
                    cv.putText(frame_debug, str(round(level_weights[i] * 10)), (x + 5, y + 5), cv.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2, cv.LINE_AA)
            producer.set_value_dict('face_detections', face_detections_json)
        
        # --------------------------------------------------
        # Send data to streaming API

        producer.send_values()

        # --------------------------------------------------
        # Preview important images

        if args.preview == True:
            # cv.imshow("frame", frame)
            cv.imshow("frame_debug", frame_debug)
            
            # Break loop by pressing ESC key
            if cv.waitKey(1) == 27:
                break
        
except KeyboardInterrupt:
    pass
finally:
    capture.release()
    cv.destroyAllWindows()