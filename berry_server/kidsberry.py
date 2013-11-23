import logging

from flask import Flask, request
import json

app = Flask(__name__)
logger = logging.getLogger(__name__)


@app.route('/')
def home():
    pass


@app.route('/create_dropbox_session', methods=['POST'])
def create_dropbox_session():
    request_credentials = json.loads(request.form)
    try:
        dropbox = DropboxClient(request_credentials)
    except:
        logger.exception("Couldn't connect to Dropbox!")

    return dropbox.client


def get_dropbox_session(access_token):
    """Try to connect to Dropbox. If the token is valid then return the client.
    """
    try:
        dropbox = DropboxClient(access_token)
    except Exception:
        logger.exception("User wasn't able to authenticate to Dropbox!")
        return

    return dropbox.client


if __name__ == '__main__':
    app.run()
