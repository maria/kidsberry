from sqlalchemy import Column, Integer, String, Datetime

from database import Base

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True)
    email = Column(String(120), unique=True)
    dropbox_access_token = Column(String(120), unique=True)
    scheduled_images_timedelta = Column(Integer)

    def __init__(self, username=None, email=None, dropbox_access_token=None,
                 scheduled_images_timedelta=1):
        self.username = username
        self.email = email
        self.dropbox_access_token = dropbox_access_token
        self.scheduled_images_timedelta = scheduled_images_timedelta

    def __repr__(self):
        return '<User %r>' % (self.username)


class ScheduledImages(Base):
    __tablename__ = 'scheduled_images'

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer(50), unique=True)
    image_url = Column(String(260), unique=True)
    timestamp = Column(Datetime)

    def __init__(self, user_id=None, image_url=None, timestamp=None):
        self.user_id = user_id
        self.image_url = image_url
        self.timestamp = timestamp

    def __repr__(self):
        return '<ScheduledImages %r>' % (self.id)
