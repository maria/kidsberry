from sqlalchemy import Column, Integer, String

from database import Base

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True)
    email = Column(String(120), unique=True)
    dropbox_access_token = Column(String(120), unique=True)

    def __init__(self, username=None, email=None, dropbox_access_token=None):
        self.username = username
        self.email = email
        self.dropbox_access_token = dropbox_access_token

    def __repr__(self):
        return '<User %r>' % (self.username)
