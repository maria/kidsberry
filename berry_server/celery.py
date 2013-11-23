from __future__ import absolute_import

from celery import Celery

DATABASE_URI = 'sqlite:////tmp/kidsberry.db'

class CeleryConfig(object):
    BROKER_URL =  'sqla+' + DATABASE_URI
    CELERY_CACHE_BACKEND = "cache://memory"


app = Celery('kidsberry', broker='amqp://', backend='sqlalchemy')
app.config_from_object(CeleryConfig)

@app.task
def schedule_pictures():
    return 'hello world'
