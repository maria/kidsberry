from celery import Celery


class CeleryConfig(object):

    CELERYBEAT_SCHEDULE = {
        'schedule_pictures':
            {
            'task': 'kidsberry.get_scheduling_pictures_task',
            'schedule': 3000,
            }
    }


def make_celery(app):
    celery = Celery(app.import_name, broker=app.config['CELERY_BROKER_URL'])
    celery.config_from_object(CeleryConfig)
    celery.conf.update(app.config)
    TaskBase = celery.Task

    class ContextTask(TaskBase):
        abstract = True
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return TaskBase.__call__(self, *args, **kwargs)
    celery.Task = ContextTask
    return celery
