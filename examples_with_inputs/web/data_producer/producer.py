import urllib.request
import json
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


TOPIC = "bitcoin_price"

dp = DataProducer()

while True:
    dp.check_topics_subscribed()
    if dp.topic_subscrived(TOPIC):
        url = "https://api.coincap.io/v2/assets/bitcoin"
        request_site = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        webpage = urllib.request.urlopen(request_site).read()
        data_json = json.loads(webpage)
        price = round(float(data_json["data"]["priceUsd"]), 2)
        dp.set_value(TOPIC, price)
        dp.send_values()
    time.sleep(10)