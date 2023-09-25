import webview
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--url", type=str, help="URL or file path to open")
parser.add_argument("--title", type=str, default="Unnamed window", help="Window title")
parser.add_argument("--x", type=int, required=True, help="X-coordinate of the window top left corner")
parser.add_argument("--y", type=int, required=True, help="Y-coordinate of the window top left corner")
parser.add_argument("--w", type=int, required=True, help="Width of the window")
parser.add_argument("--h", type=int, required=True, help="Height of the window")

args = parser.parse_args()
assert args.x >= 0
assert args.y >= 0
assert args.w >= 100
assert args.h >= 100

if args.url is None:
    curr_dir_path = os.path.dirname(os.path.realpath(__file__))
    path_html_file = os.path.join(curr_dir_path, "index.html")
    if os.path.exists(path_html_file):
        args.url = path_html_file
    else:
        html_files = sorted([os.path.join(curr_dir_path, f) for f in os.listdir(curr_dir_path) if f.endswith(".html")])
        assert len(html_files) > 0
        args.url = html_files[0]

print("Opening URL: {}".format(args.url))

webview.create_window(args.title, args.url, frameless=True, x=args.x, y=args.y, width=args.w, height=args.h)
webview.start()