from flask import Flask, request, session, redirect, url_for
import json

from database import db_session
from settings_local import FLASK_SECRET_KEY

app = Flask(__name__)
app.secret_key = FLASK_SECRET_KEY


@app.route('/')
def home():
    response = {'response': 'HI!'}
    return json.dumps(response)


@app.route('/login', methods=['POST'])
def login():
    request_credentials = json.loads(request.form)
    if session.get(request_credentials['username']):
        response = {'response': 'You are already logged in!'}
    else:
        session['username'] = request_credentials['username']
        response = {'response': 'Successfully logged in!',
                    'username': session['username']}

    return json.dumps(response)


@app.route('/logout')
def logout():
    session.pop('username', None)
    response = {'response': 'Successfully logged out!'}
    return json.dumps(response)


@app.route('/create_dropbox_session', methods=['POST'])
def create_dropbox_session():
    request_credentials = json.loads(request.form)
    try:
        dropbox = DropboxClient(request_credentials)
    except:
        app.logger.warning("Couldn't connect to Dropbox!")

    return dropbox.client


def get_dropbox_session(access_token):
    """Try to connect to Dropbox. If the token is valid then return the client.
    """
    try:
        dropbox = DropboxClient(access_token)
    except Exception:
        app.logger.warning("User wasn't able to authenticate to Dropbox!")
        return

    return dropbox.client


@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()


if __name__ == '__main__':
    app.run()
