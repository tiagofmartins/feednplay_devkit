import cv2 as cv
import mediapipe as mp
import copy
import time

# https://github.com/google/mediapipe/blob/master/docs/solutions/face_detection.md

preview = True
camera_name = "cam1"



class TopicsController:
    
    # topics = [
    #     "rgb_1080", "rgb_720", "rgb_480",
    #     "gray_1080", "gray_720", "gray_420",
    #     "movement_10", "movement_25",
    #     "faces", "hands", "poses",
    #     "faces_debug", "hands_debug", "poses_debug"
    # ]
    topics = []            
    values = []
    topics_subscrived = []
    time_last_update_topics_subscribed = 0
    
    def __init__(self, preffix):
        self.preffix = preffix + ("_" if not preffix.endswith("_") else "")
    
    def __add_preffix(self, topic):
        return self.preffix + topic

    def update_topics_subscribed(self, every_seconds=5):
        if time.time() - self.time_last_update_topics_subscribed > every_seconds:
            self.time_last_update_topics_subscribed = time.time()
            for i in range(len(self.topics)):
                topic = self.__add_preffix(self.topics[i])
                self.topics_subscrived[i] = True # TODO jncor: set to True if topic is subscribed
    
    def topic_is_subscrived(self, topic):
        if topic not in self.topics:
            self.topics.append(topic)
            self.values.append(None)
            self.topics_subscrived.append(False)
        return self.topics_subscrived[self.topics.index(topic)]
    
    def set_value(self, topic, value):
        assert topic in self.topics
        self.values[self.topics.index(topic)] = value

    def send_values(self):
        for i in range(len(self.topics)):
            value = self.values[i]
            if value is not None:
                topic = self.__add_preffix(self.topics[i])
                # TODO jncor: send data (topic, value) to API
                self.values[i] = None




def main():
    tc = TopicsController("cam1")
    
    # model_selection=0 ---> select a short-range model that works best for faces within 2 meters from the camera
    # model_selection=1 ---> select a full-range model best for faces within 5 meters
    face_detection = mp.solutions.face_detection.FaceDetection(model_selection=1, min_detection_confidence=0.95)

    cap = cv.VideoCapture(0)
    cap.set(cv.CAP_PROP_FRAME_WIDTH, 1920)
    cap.set(cv.CAP_PROP_FRAME_HEIGHT, 1080)

    while cap.isOpened():
        success, image = cap.read()
        if not success:
            print("Ignoring empty camera frame")
            continue

        tc.update_topics_subscribed()

        image = cv.flip(image, 1)
        # image = cv.cvtColor(image, cv.COLOR_BGR2RGB)

        # ---------- RGB and grayscale images

        for h in (1080, 720, 480, 240):
            topic_rgb = "rgb_{}".format(h)
            topic_gray = "gray_{}".format(h)
            rgb_subscribed = tc.topic_is_subscrived(topic_rgb)
            gray_subscribed = tc.topic_is_subscrived(topic_gray)
            if rgb_subscribed or gray_subscribed:
                if image.shape[0] > h:
                    w = int(image.shape[1] * (h / float(image.shape[0])))
                    image_rgb = cv.resize(image, (w, h), interpolation=cv.INTER_LINEAR)
                else:
                    image_rgb = image
                if rgb_subscribed:
                    tc.set_value(topic_rgb, image_rgb)
                if gray_subscribed:
                    image_gray = cv.cvtColor(image_rgb, cv.COLOR_RGB2GRAY)
                    tc.set_value(topic_gray, image_gray)
        
        # ---------- faces

        faces_subscribed = tc.topic_is_subscrived("faces")
        faces_debug_subscribed = tc.topic_is_subscrived("faces_debug")
        if faces_subscribed or faces_debug_subscribed or preview:
            if faces_subscribed:
                faces_data = {"image_size": {"width": image.shape[1], "height": image.shape[0]}, "faces": []}
            image_faces_debug = None
            if faces_debug_subscribed or preview:
                image_faces_debug = copy.deepcopy(image)
            results = face_detection.process(image)
            if results.detections:
                for detection in results.detections:
                    if faces_subscribed:
                        bb = detection.location_data.relative_bounding_box
                        keypoints = detection.location_data.relative_keypoints
                        faces_data["faces"].append({
                            "id": detection.label_id[0],
                            "score": round(detection.score[0], 3),
                            "x": round(bb.xmin, 3),
                            "y": round(bb.ymin, 3),
                            "width": round(bb.width, 3),
                            "height": round(bb.height, 3),
                            "keypoints": [[round(p.x, 3), round(p.y, 3)] for p in keypoints]
                        })
                    if image_faces_debug is not None:
                        image_faces_debug = draw_detection(image_faces_debug, detection)
            if faces_subscribed:
                tc.set_value("faces", faces_data)
            if faces_debug_subscribed:
                tc.set_value("faces_debug", image_faces_debug)
        
        # ---------- hands
        # if topic_hands:
        #     pass
        
        if preview:
            cv.imshow("", image_faces_debug)
            if cv.waitKey(1) == 27:
                break

    cap.release()
    cv.destroyAllWindows()

def draw_detection(image, detection):
    img_w, img_h = image.shape[1], image.shape[0]
    
    bbox = detection.location_data.relative_bounding_box
    bbox.xmin = int(bbox.xmin * img_w)
    bbox.ymin = int(bbox.ymin * img_h)
    bbox.width = int(bbox.width * img_w)
    bbox.height = int(bbox.height * img_h)
    cv.rectangle(image, (int(bbox.xmin), int(bbox.ymin)), (int(bbox.xmin + bbox.width), int(bbox.ymin + bbox.height)), (255, 255, 255), 1)

    for p in detection.location_data.relative_keypoints:
        cv.circle(image, (int(p.x * img_w), int(p.y * img_h)), 5, (255, 255, 255), -1)
    
    text = "[{}] {}".format(detection.label_id[0], round(detection.score[0], 3))
    cv.putText(image, text, (int(bbox.xmin), int(bbox.ymin) - 20), cv.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 1, cv.LINE_AA)

    return image

if __name__ == '__main__':
    main()