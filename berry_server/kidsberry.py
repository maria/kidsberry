import json

from flask import Flask, request, session, redirect, url_for

from camera_picture import CameraPicture
from camera_video import CameraVideo
from database import db_session
from models import User
from settings_local import FLASK_SECRET_KEY

DEFAULT_VIDEO_DURATION = 120

app = Flask(__name__)


@app.route('/')
def home():
    response = {'response': 'HI!'}
    return json.dumps(response)


@app.route('/sign_up', methods=['POST'])
def sign_up():
    request_data = json.loads(request.data)
    new_user = create_new_user(request_data['username'],
                               request_data['email'])
    user = User.query.filter(User.email == new_user.email)[0]

    response = {'response': 'Your account was successfully created',
                'data': {'id': user.id}}
    return json.dumps(response)


@app.route('/login', methods=['POST'])
def login():
    request_data = json.loads(request.data)
    username = request_data['username']
    if session.get(username):
        response = {'response': 'You are already logged in!'}
    else:
        if User.query.filter(User.username == username).count() > 0:
            user = User.query.get(User.username == username)
        else:
            create_new_user(username, request_data.get('email'))

    session['username'] = username
    response = {'response': 'Successfully logged in!',
                'data': {'username': session['username']}}

    return json.dumps(response)


def create_new_user(username, email=None):
    new_user = User(username=username, email=email)
    db_session.add(new_user)
    return new_user


@app.route('/logout')
def logout():
    session.pop('username', None)
    response = {'response': 'Successfully logged out!'}
    return json.dumps(response)


@app.route('/create_dropbox_session', methods=['POST'])
def create_dropbox_session():
    """Assert if the given access token is the one saved for the user in the
    database, else update the access_token.
    Return a new Dropbox client session for the user.
    """
    user = User.query.get(User.username == session['username'])
    user_access_token = user.dropbox_access_token
    access_token = json.loads(json.loads(request.data))['access_token']

    if user_access_token != access_token:
        user.update({'dropbox_access_token': access_token})
    return get_dropbox_session(access_token)


def get_dropbox_session(access_token=None):
    """Try to connect to Dropbox. If the token is valid then return the client.
    """
    if not access_token:
        user = User.query.get(User.username == session['username'])
        access_token = user.dropbox_access_token
    try:
        dropbox = DropboxClient(access_token)
    except Exception:
        app.logger.warning("User wasn't able to authenticate to Dropbox!")
        return

    return dropbox.client


@app.route('/take_picture')
def take_picture():
    """Connect to the RasberryPi and take a picture using the wrapper class.
    Upload the file to Dropbox and send the URL to the client.
    """
    camera = CameraPicture()
    filename = camera.take_picture()

    client = get_dropbox_session()
    file_url = client.upload(filename)

    response = {'response': 'OK', 'data': {'file_url': file_url}}
    return json.dumps(response)


@app.route('/take_video')
def take_video():
    """Take a video of a fixed duration, if none is given set the default to
    2 minutes, upload the video on Dropbox and return the file URL.
    """
    duration = json.loads(json.loads(request.data)).get('duration')
    if not duration:
        duration = DEFAULT_VIDEO_DURATION

    video = CameraVideo()
    filename = video.take_video(duration)

    client = get_dropbox_session()
    video_url = client.upload(filename)

    response = {'data': {'video_url': video_url}}


@app.route('/live_preview', methods=['POST, DELETE'])
def live_preview():
    """If the client makes a POST request start the live preview, and add the
    CameraVideo object to the session to be able to end the live preview once
    the client makes a DELETE request.
    """
    if request.method == 'POST':
        video = CameraVideo()
        session['video'] = video
        video.start_live_preview()

    elif request.method == 'DELETE' and session.get('video'):
        video = session['video']
        video.end_live_preview()


@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()


if __name__ == '__main__':
    app.config.from_object('kidsberry_config.KidsberryConfig')
    import logging
    file_handler = logging.FileHandler('/tmp/kidsberry.log')
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    app.run()
