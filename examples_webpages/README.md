Demonstration of how to open a webpage in a frameless window.

### Example

Example of a command line that opens the University of Coimbra webpage in a frameless window with the top left corner positioned at the coordinates (44, 66) and with a size of 800 by 600 pixels.

```console
python show_webpage.py --url https://www.uc.pt --x 44 --y 66 --w 800 --h 600
```

### Requirements

The Python script that launches a given webpage with a frameless browser requires the library `webview` which can be installed by running the following command line:

```console
python -m pip install pywebview
```