import confluent_kafka
import urllib.request
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


def get_bitcoin_price():
    url = 'https://api.coincap.io/v2/assets/bitcoin'
    request_site = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    webpage = urllib.request.urlopen(request_site).read()
    data_json = json.loads(webpage)
    price = round(float(data_json['data']['priceUsd']), 2)
    return price


# Topic name
topic = 'bitcoin_price_usd'

# Interval in seconds between new values production
production_period = 5

# Other variables
producer = FnpDataProducer(callback=False)

while True:
    t = time.time()
    if producer.need_to_produce_topic(topic):
        try:
            price = get_bitcoin_price()
        except:
            print("Unable to get price")
        else:
            producer.set_value(topic, get_bitcoin_price())
            producer.send_values()
    nap_time = production_period - (time.time() - t)
    if nap_time > 0:
        time.sleep(nap_time)