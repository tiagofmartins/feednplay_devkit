# Data streaming

FeedNPlay implements an API that facilitates the creation of contents capable of reacting in real-time to external data such as values produced by sensors or images from video cameras.

This API is based on a paradigm of data producers and consumers:

- A **producer** consists of a computer program that collects, processes and makes available data organised into one or multiple **topics**.
- A **consumer** consists of a computer program that reads data relating to one or more **topics**.
- Each data topic can be read by different consumers at the same time.

This paradigm allows different content to use the same data simultaneously. For example, we can control different Processing sketches using the same Arduino microcontroller or any other data source.

This API is implemented using the open-source distributed event streaming platform [Apache Kafka](https://kafka.apache.org).

## How to run the API

### Installation (you just need to do this once)

1. Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) application
2. Install required Python libs by running the following command line:
```console
python -m pip install confluent-kafka opencv-python pyserial
```
3. Download this repository

### Run API

1. Open Docker Desktop application
2. Delete existing containers, images and volumes in the Docker Desktop application
3. Open terminal
4. Move to the directory that contains the file [`docker-compose.yaml`](docker-compose.yaml). For example, if you downloaded this repository to the folder `/Users/YourName/Downloads` you should run the following command line:
```console
cd /Users/YourName/Downloads/feednplay_devkit/data_streaming
```
5. Start services defined in the `docker-compose.yaml` file by running the following command line:
```console
docker compose up --build
```
6. Execute producer(s) program(s)
7. Execute consumer(s) program(s)