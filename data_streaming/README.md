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
4. Move to the directory that contains the file [`docker-compose.yaml`](other_file.md). For example, if you downloaded this repository to the folder `/Users/YourName/Downloads` you should run the following command line:
```console
cd /Users/YourName/Downloads/feednplay_devkit/data_streaming
```
4. Start services defined in the `docker-compose.yaml` file by running the following command line:
```console
docker compose up --build
```
5. Execute producer(s) program(s)
6. Execute consumer(s) program(s)

```markdown
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

### Text

```markdown
_italic_ or *italic*

**bold** or __bold__

~~strikethrough~~
```

### Blockquotes

```markdown
> This is a blockquote
```

### Horizontal Rule

```markdown
---

***

___
```

### Lists

```markdown
1. Ordered list
2. ...

- Unordered list
* With *
+ With +
```

### Links

```markdown
[Inine](https://a.com)

[Inline with title](https://a.com "A title")

[Reference][1]

[Link to file](./Docs/SETUP.md)

[1]: https://a.com
```

### Images

```markdown
![Inline](https://a.com/logo.png)

![Reference][logo]

[logo]: https://a.com/logo.png
```

### Code

````markdown
`Inline code`

```javascript
const x = 5;
const plusTwo = a => a + 2;
```
````

### Tables

```markdown
| Column 1      | Column 2      |  Column 3 |
| ------------- |:-------------:| ---------:|
| Col 3 is      | right-aligned | $1600     |
| Col 2 is      | centered      |   $12     |
| Tables        | are neat      |    $1     |
```

### HTML

```markdown
<a href="https://a.com">Link</a>
<img src="https://a.com/logo.png" width="100">
```
