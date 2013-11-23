from settings_local import DATABASE_URI, FLASK_SECRET_KEY


class KidsberryConfig(object):
    DEBUG = False
    TESTING = False
    DATABASE_URI = DATABASE_URI
    SECRET_KEY = FLASK_SECRET_KEY
