import serial.tools.list_ports
import serial
import time


class DataProducer:
    topics_being_produced = {}
    topics_subscrived = []
    time_last_check_topics_subscribed = 0
    
    def __init__(self, preffix=""):
        self.preffix = preffix
    
    def __add_preffix(self, topic):
        return self.preffix + topic
    
    def check_topics_subscribed(self, frequency=5):
        if time.time() - self.time_last_check_topics_subscribed > frequency:
            self.time_last_check_topics_subscribed = time.time()
            self.topics_subscrived = [] # TODO get list of topics that were recently subscribed (last 2 minutes?)
    
    def topic_subscrived(self, topic):
        return self.__add_preffix(topic) in self.topics_subscrived or True # TODO remove this last condition
        
    def set_value(self, topic, value):
        self.topics_being_produced[topic] = value
        
    def send_values(self):
        for topic, value in self.topics_being_produced.items():
            topic = self.__add_preffix(topic)
            # TODO send data (topic, value) to API
            print('{}: {}'.format(topic, value))
        self.topics_being_produced.clear()


def get_arduino_ports():
    # More info: https://pyserial.readthedocs.io/en/latest/tools.html
    arduino_ports = {}
    for port in serial.tools.list_ports.comports():
        if port.manufacturer and "arduino" in port.manufacturer.lower():
            arduino_ports[port.serial_number] = port.device
    return arduino_ports

def get_port_by_serial_number(sn):
    # More info: https://pyserial.readthedocs.io/en/latest/tools.html
    for port in serial.tools.list_ports.comports():
        if port.serial_number == sn:
            return port.device
    return None


TOPIC_1 = "button_pressed"
TOPIC_2 = "button_pressed_last_5_secs"
TOPIC_3 = "potentiometer_value"

dp = DataProducer()

port_name = get_port_by_serial_number("85036313530351304291")
assert port_name is not None
arduino_port = serial.Serial(port_name, 9600)
time_last_button_press = 0

while True:
    dp.check_topics_subscribed()
    
    data = str(arduino_port.readline().decode("ascii")).split()
    for piece in data:

        if piece.startswith("b"):
            if dp.topic_subscrived(TOPIC_1) or dp.topic_subscrived(TOPIC_2):
                button_is_pressed = int(piece[1:]) == 0
                if button_is_pressed:
                    time_last_button_press = time.time()
                if dp.topic_subscrived(TOPIC_1):
                    dp.set_value(TOPIC_1, button_is_pressed)
                if dp.topic_subscrived(TOPIC_2):
                    button_pressed_recently = (time.time() - time_last_button_press) <= 5
                    dp.set_value(TOPIC_2, button_pressed_recently)
        
        elif piece.startswith("p"):
            if dp.topic_subscrived(TOPIC_3):
                value = int(piece[1:])
                dp.set_value(TOPIC_3, value)
    
    dp.send_values()
    time.sleep(0.01)