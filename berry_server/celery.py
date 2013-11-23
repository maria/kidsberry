from __future__ import absolute_import

from celery import Celery


class CeleryConfig(object):
    BROKER_URL =  'sqla+sqlite:////tmp/kidsberry.db'
    CELERY_CACHE_BACKEND = "cache://memory"


app = Celery('kidsberry')
app.config_from_object(CeleryConfig)

CELERY_IMPORTS = ('kidsberry')

CELERYBEAT_SCHEDULE = {
    'get_scheduling_pictures_task': {
        'task': 'kidsberry.get_scheduling_pictures_task',
        'schedule': 300,
    }
}

if __name__ == '__main__':
    app.start()
