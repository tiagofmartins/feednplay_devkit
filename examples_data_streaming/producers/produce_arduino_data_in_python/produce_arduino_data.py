import confluent_kafka
import serial.tools.list_ports
import serial
import json
import time


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


def get_arduino_ports():
    # More info: https://pyserial.readthedocs.io/en/latest/tools.html
    arduino_ports = {}
    for port in serial.tools.list_ports.comports():
        if port.manufacturer and 'arduino' in port.manufacturer.lower():
            arduino_ports[port.serial_number] = port.device
    return arduino_ports


def get_port_by_serial_number(sn):
    # More info: https://pyserial.readthedocs.io/en/latest/tools.html
    for port in serial.tools.list_ports.comports():
        if port.serial_number == sn:
            return port.device
    return None


# Serial number of Arduino board
arduino_board_serial_number = '85036313530351304291'

# Topics' names
topic_1 = 'button_pressed'
topic_2 = 'button_pressed_last_5_secs'
topic_3 = 'potentiometer_value'

# Other variables
producer = FnpDataProducer(callback=False)
arduino_port = None
time_last_button_press = 0

while True:

    # Initiate connection with Arduino board
    if arduino_port is None:
        port_name = get_port_by_serial_number(arduino_board_serial_number)
        if port_name is not None:
            print('Opening serial port {}'.format(port_name))
            arduino_port = serial.Serial(port_name, 9600)
        else:
            print('Unable to find serial port of Arduino board {}'.format(arduino_board_serial_number))
            time.sleep(2)
            continue
    
    # Wait for a new line
    try:
        message = str(arduino_port.readline().decode('ascii'))
    except serial.serialutil.SerialException:
        arduino_port = None
        print('Unable to read line from serial port')
        continue
    
    # Split received message into tokens
    message_tokens = message.split()
    for token in message_tokens:

        # Parse button state
        if token.startswith('b'):
            if producer.need_to_produce_topic(topic_1) or producer.need_to_produce_topic(topic_2):
                button_is_pressed = int(token[1:]) == 1
                if button_is_pressed:
                    time_last_button_press = time.time()
                if producer.need_to_produce_topic(topic_1):
                    producer.set_value(topic_1, button_is_pressed)
                if producer.need_to_produce_topic(topic_2):
                    button_pressed_recently = (time.time() - time_last_button_press) <= 5
                    producer.set_value(topic_2, button_pressed_recently)
        
        # Parse potentiometer value
        elif token.startswith('p'):
            if producer.need_to_produce_topic(topic_3):
                value = int(token[1:])
                producer.set_value(topic_3, value)
    
    # Send values to server
    producer.send_values()