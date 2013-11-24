from __future__ import absolute_import

from celery import Celery


class CeleryConfig(object):
    """Update celery configuration params to the app specific params.
    Use this settings to create a celery app which has to be run as a daemon.
    """
    CELERYD_MAX_TASKS_PER_CHILD = 1
    BROKER_URL =  'sqla+sqlite:////tmp/kidsberry.db'
    CELERY_CACHE_BACKEND = "cache://memory"

    CELERY_IMPORTS = ('kidsberry')

    CELERYBEAT_SCHEDULE = {
        'get_scheduling_pictures_task': {
            'task': 'kidsberry.get_scheduling_pictures_task',
            'schedule': 300,
        }
    }


def make_celery():
    instance = Celery('kidsberry')
    instance.config_from_object(CeleryConfig)
    return instance

kids_celery = make_celery()
# Quick shortcut to import the @task decorator directly.
task = kids_celery.task

if __name__ == '__main__':
    celery = kids_celery
