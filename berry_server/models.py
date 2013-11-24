from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime

from database import Base

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True)
    email = Column(String(120), unique=True)
    dropbox_access_token = Column(String(120), unique=True)
    scheduled_images_timedelta = Column(Integer)
    last_image_timeframe = Column(DateTime)

    def __init__(self, username=None, email=None, dropbox_access_token=None,
                 scheduled_images_timedelta=1, last_image_timeframe=None):
        self.username = username
        self.email = email
        self.dropbox_access_token = dropbox_access_token
        self.scheduled_images_timedelta = scheduled_images_timedelta
        self.last_image_timeframe = last_image_timeframe or datetime.now()

    def __repr__(self):
        return '<User %r>' % (self.username)
