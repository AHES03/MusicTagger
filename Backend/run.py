import argparse
import sys
import os
import uvicorn

if __name__ == '__main__':
    # When bundled by PyInstaller, data files land in sys._MEIPASS
    if hasattr(sys, '_MEIPASS'):
        sys.path.insert(0, sys._MEIPASS)

    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    uvicorn.run('main:app', host=args.host, port=args.port)
