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
            if msg.topic().startswith('image_'):
                message += 'image'
            else:
                message += msg.value().decode('utf-8')
            print(message)
    
    def __add_preffix(self, topic):
        return self.topics_preffix + topic

# --------------------------------------------------
# Constants

# interaction_corners = [[0.15, 0.13], [0.83, 0.13], [0.87, 0.70], [0.10, 0.68]] # horizontal flip
interaction_corners = [[0.12, 0.32], [0.87, 0.30], [0.83, 0.87], [0.16, 0.88]] # with 180 rotation

# --------------------------------------------------
# Variables

p = FnpDataProducer(callback=False)
subtractor_knn = cv.createBackgroundSubtractorKNN(history=2500, dist2Threshold=400, detectShadows=False)
perspective_transform = None
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
        # Rotate image so the FeedNPlay's displays appear on top

        # frame = cv.flip(frame, 1)
        frame = cv.rotate(frame, cv.ROTATE_180)
        frame_debug = frame.copy()
        
        # --------------------------------------------------
        # Perspective transformation
        # https://theailearner.com/tag/cv2-warpperspective/
        # https://pyimagesearch.com/2014/08/25/4-point-opencv-getperspective-transform-example/

        # Draw limits of the interaction area
        cv.polylines(frame_debug, pts=[np.array(interaction_corners, np.int32)], isClosed=True, color=(255, 255, 255), thickness=1)

        # Calculate perspective transform only once
        if perspective_transform is None:

            # Make coordinates of corners absolute
            interaction_corners = [[c[0] * frame.shape[1], c[1] * frame.shape[0]] for c in interaction_corners]
            pt_A, pt_B, pt_C, pt_D = interaction_corners
            
            # Derive maximum width and height of the interaction area from its corners
            dist_AB = np.sqrt(((pt_A[0] - pt_B[0]) ** 2) + ((pt_A[1] - pt_B[1]) ** 2))
            dist_BC = np.sqrt(((pt_B[0] - pt_C[0]) ** 2) + ((pt_B[1] - pt_C[1]) ** 2))
            dist_CD = np.sqrt(((pt_C[0] - pt_D[0]) ** 2) + ((pt_C[1] - pt_D[1]) ** 2))
            dist_DA = np.sqrt(((pt_D[0] - pt_A[0]) ** 2) + ((pt_D[1] - pt_A[1]) ** 2))
            max_width = int(max(dist_AB, dist_CD))
            max_height = int(max(dist_BC, dist_DA))

            # Calculate perspective transform
            input_points = np.float32([pt_A, pt_B, pt_C, pt_D])
            output_points = np.float32([[0, 0], [max_width - 1, 0], [max_width - 1, max_height - 1], [0, max_height - 1]])
            perspective_transform = cv.getPerspectiveTransform(input_points, output_points)
        
        # Apply perspective transform
        warped_crop = cv.warpPerspective(frame, perspective_transform, (max_width, max_height), flags=cv.INTER_LINEAR)
        warped_crop_debug = warped_crop.copy()

        # --------------------------------------------------
        # Produce images

        images_to_produce = {'frame': frame, 'roi': warped_crop}
        for option, img in images_to_produce.items():
            resolution_max = min(img.shape[0], 1080)
            resolutions = {'full': resolution_max,
                           'half': int(resolution_max / 2),
                           'quarter': int(resolution_max / 4)}
            for res in resolutions:
                topic_rgb = "image_{}_rgb_{}".format(option, res)
                topic_gray = "image_{}_gray_{}".format(option, res)
                rgb_required = p.need_to_produce_topic(topic_rgb)
                gray_required = p.need_to_produce_topic(topic_gray)
                if rgb_required or gray_required:
                    if img.shape[0] != resolutions[res]:
                        w = int(img.shape[1] * (resolutions[res] / float(img.shape[0])))
                        image_rgb = cv.resize(img, (w, resolutions[res]), interpolation=cv.INTER_AREA)
                    else:
                        image_rgb = img
                    if rgb_required:
                        p.set_value_bytes(topic_rgb, cv.imencode('.jpg', image_rgb)[1].tobytes())
                    if gray_required:
                        image_gray = cv.cvtColor(image_rgb, cv.COLOR_BGR2GRAY)
                        p.set_value_bytes(topic_gray, cv.imencode('.jpg', image_gray)[1].tobytes())
        
        # --------------------------------------------------
        # Frame difference

        roi_diff = None
        diff_needed = False
        matrix_num_cols_options = (360, 90)
        for cols in matrix_num_cols_options:
            topic = 'roi_diff_{}cols'.format(cols)
            if p.need_to_produce_topic(topic):
                diff_needed = True
                if previous_frame is None:
                    break
                if roi_diff is None:
                    roi_diff = cv.absdiff(warped_crop, previous_frame)
                    roi_diff = cv.cvtColor(roi_diff, cv.COLOR_BGR2GRAY)
                rows = int(roi_diff.shape[0] * (cols / roi_diff.shape[1]))
                roi_diff_resised = cv.resize(roi_diff, (cols, rows), interpolation=cv.INTER_AREA)
                roi_diff_matrix = np.asarray(roi_diff_resised).tolist()
                roi_diff_json = {'w': cols, 'h': rows, 'matrix': roi_diff_matrix}
                p.set_value_dict(topic, roi_diff_json)
        if diff_needed:
            previous_frame = warped_crop.copy()
        
        # --------------------------------------------------
        # Background subtraction
        # https://docs.opencv.org/3.4/d1/dc5/tutorial_background_subtraction.html
        # https://medium.com/@abbessafa1998/motion-detection-techniques-with-code-on-opencv-18ed2c1acfaf

        # # Calculate motion mask
        # motion_mask = subtractor_knn.apply(warped_crop)
        # # background = subtractor_knn.getBackgroundImage()
        
        # # Simplify motion mask
        # blur_size = 0.1 * motion_mask.shape[0]
        # blur_size = math.ceil(blur_size) // 2 * 2 + 1
        # motion_mask_smooth = cv.GaussianBlur(motion_mask, (blur_size, blur_size), 0)
        # _, motion_mask_smooth = cv.threshold(motion_mask_smooth, 100, 255, cv.THRESH_BINARY + cv.THRESH_OTSU)
        
        # # Calculate contours
        # contours, _ = cv.findContours(motion_mask_smooth, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
        # contour_area_min = 0.005 * motion_mask_smooth.shape[0] * motion_mask_smooth.shape[1]
        # presences = []
        # for contour in contours:
        #     # Skip contour if too small
        #     x, y, w, h = cv.boundingRect(contour)
        #     if w * h < contour_area_min:
        #         continue

        #     # Contour bounds
        #     cv.rectangle(warped_crop_debug, pt1=(x, y), pt2=(x + w, y + h), color=(255, 255, 255), thickness=1, lineType=cv.LINE_AA)

        #     # Contour centroid
        #     m = cv.moments(contour)
        #     centroidX = int(m['m10'] / m['m00'])
        #     centroidY = int(m['m01'] / m['m00'])
        #     cv.circle(warped_crop_debug, center=(centroidX, centroidY), radius=2, color=(255, 255, 255), thickness=-1, lineType=cv.LINE_AA)

        #     # Contour approximation
        #     contourn_approx = cv.approxPolyDP(contour, epsilon=0.01 * cv.arcLength(contour, True), closed=True)
        #     vertexes_array_1D = contourn_approx.ravel() # Flatten array
        #     contour_vertexes = [[vertexes_array_1D[i], vertexes_array_1D[i + 1]] for i in range(0, len(vertexes_array_1D), 2)]
        #     cv.drawContours(warped_crop_debug, contours=[contourn_approx], contourIdx=0, color=(255, 255, 255), thickness=1, lineType=cv.LINE_AA)

        #     # Create dictionary
        #     presences.append({
        #         'bounds': {'x': x, 'y': y, 'w': w, 'h': h},
        #         'contour': contour_vertexes,
        #         'centroid': {'x': centroidX, 'y': centroidY}
        #     })

        # # TODO produce topic [json_presences]
        
        # --------------------------------------------------

        # TODO produce debug images

        # --------------------------------------------------
        # Send data to streaming API

        p.send_values()

        # --------------------------------------------------
        # Preview important images

        if args.preview == True:
            # Show important images
            # cv.imshow("frame", frame)
            cv.imshow("frame_debug", frame_debug)
            # cv.imshow("motion_mask", motion_mask)
            cv.imshow("warped_crop_debug", warped_crop_debug)
            if roi_diff is not None:
                cv.imshow("roi_diff", roi_diff)
            
            # Break loop by pressing ESC key
            if cv.waitKey(1) == 27:
                break
        
except KeyboardInterrupt:
    pass
finally:
    capture.release()
    cv.destroyAllWindows()