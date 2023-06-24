import serial.tools.list_ports
import serial
import time

def publish(data):
    assert type(data) is dict
    # TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> send data to API here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    for topic, value in data.items():
        print("{} -> {}".format(topic, value))

def secs_since_last_consumption(topic):
    # TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> return number of seconds since last consumption <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    return 0

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

def main():
    port_name = get_port_by_serial_number("85036313530351304291")
    arduino_port = serial.Serial(port_name, 9600)

    time_last_button_press = 0

    while True:
        data = str(arduino_port.readline().decode("ascii")).strip()

        if data.startswith("b"):
            topic1 = "button_pressed"
            topic2 = "button_pressed_recent_5secs"
            if min(secs_since_last_consumption(topic1), secs_since_last_consumption(topic2)) < 600:
                button_is_pressed = int(data[1:]) == 0
                if button_is_pressed:
                    time_last_button_press = time.time()
                button_pressed_in_the_last_5_secs = (time.time() - time_last_button_press) <= 5
                publish({topic1: button_is_pressed, topic2: button_pressed_in_the_last_5_secs})

        elif data.startswith("p"):
            topic = "potentiometer_value"
            if secs_since_last_consumption(topic) < 600:
                value = int(data[1:])
                publish({topic: value})
        
        else:
            assert False
        
        time.sleep(0.05)

if __name__ == "__main__":
    main()