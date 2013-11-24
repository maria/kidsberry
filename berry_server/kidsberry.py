import json
import datetime

from flask import Flask, request, session, redirect, url_for, g

from camera_picture import CameraPicture
from camera_video import CameraVideo
from celery_tasks import make_celery
from database import db_session
from dropbox_client import DropboxClient
from models import User
from settings_local import FLASK_SECRET_KEY

DEFAULT_VIDEO_DURATION = 120

app = Flask(__name__)
app.config.from_object('kidsberry_config.KidsberryConfig')
celery = make_celery(app)


@app.route('/')
def home():
    response = {'response': 'HI!'}
    return json.dumps(response)


@app.route('/sign_up', methods=['POST'])
def sign_up():
    """Create a new account if no other account with the same email address
    exists.
    """
    request_data = json.loads(request.data)
    if User.query.filter(User.email == request_data['email']).count() > 0:
        response = {'response': 'You already have an account!'}
    else:
        new_user = create_new_user(request_data['username'],
                                   request_data['email'])
        user = User.query.filter(User.email == new_user.email)[0]

        response = {'response': 'Your account was successfully created',
                    'data': {'id': user.id}}
    return json.dumps(response)


@app.route('/login', methods=['POST'])
def login():
    """Create a new session if no session exists for the user with the given
    username.
    """
    request_data = json.loads(request.data)
    username = request_data['username']
    if session.get(username):
        response = {'response': 'You are already logged in!'}
    else:
        if User.query.filter(User.username == username).count() > 0:
            user = User.query.filter(User.username == username)[0]
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
    request_data = json.loads(request.data)

    user = User.query.filter(User.username == session['username'])[0]
    user_access_token = user.dropbox_access_token
    access_token = request_data.get('access_token')

    if user_access_token != access_token:
        user.dropbox_access_token = access_token
        db_session.add(user)

    return get_dropbox_session(access_token)


def get_dropbox_session(access_token=None):
    """Try to connect to Dropbox. If the token is valid then return the client.
    """
    if not access_token:
        user = User.query.filter(User.username == session['username'])[0]
        access_token = user.dropbox_access_token
    try:
        dropbox = DropboxClient(access_token)
    except Exception:
        app.logger.warning("User wasn't able to authenticate to Dropbox!")
        return

    return dropbox


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


@app.route('/live_preview', methods=['GET', 'DELETE'])
def live_preview():
    """If the client makes a POST request start the live preview, and add the
    CameraVideo object to the session to be able to end the live preview once
    the client makes a DELETE request.
    """
    if request.method == 'GET':
        video = CameraVideo()
        setattr(g, 'video', video)
        filename = video.start_live_preview()
        #client = get_dropbox_session(session['username'])
        #client.upload(filename)
    elif request.method == 'DELETE' and hasattr(g,'video'):
        video = g.video
        video.end_live_preview()


@app.route('/schedule_pictures', methods=['POST'])
def schedule_pictures():
    """Set a scheduling timeframe for a user, in order to take pictures """
    request_data = json.loads(request.data)
    user = User.query.filter(User.username == session['username'])
    user.scheduled_images_timedelta = request_data['timedelta']
    db_session.add(user)


@celery.task()
def get_scheduling_pictures_task():
    """Get the list of users who have a scheduled timeframe for taking pictures,
    and for which we didn't took pictures in expected timeframe.
    For each user take a picture and save it in the database.
    """
    users_ids = User.query.all()
    for user_id in users_ids:
        if should_take_pictures(user_id):
            scheduled_pictures_task(user_id)


def should_take_pictures(user_id):
    """Assert if we should take new pictures for the user. Hence the last picture
    was taken outside the expected timeframe.
    """
    user = User.query.filter(User.id == user_id)
    timedelta = datetime.datetime.now() - user.scheduled_images_timedelta
    return True if user.last_image_timeframe < timedelta else False


def scheduled_pictures_task(user_id):
    """Upload a picture to Dropbox and save the timestamp in the database,
    to check in the future if we should take a new scheduled picture.
    """
    camera = CameraPicture()
    picture = camera.take_picture()

    client = get_dropbox_session()
    image_url = client.upload(picture)

    timestamp = datetime.datetime.now()
    user = User.query.filter(Username.id == user_id)
    user.last_image_timeframe = timestamp
    db_session.add(user)


@app.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()


if __name__ == '__main__':
    import logging
    file_handler = logging.FileHandler('/tmp/kidsberry.log')
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    app.run()
