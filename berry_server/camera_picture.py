from time import sleep
from datetime import datetime

from SimpleCV import Camera


class CameraPicture(object):

    #def __init__(self):
        #self.my_camera = Camera(prop_set={'width':320, 'height': 240})

    def take_picture(self):
	if hasattr(self, 'my_camera') is False:
	    self.my_camera = Camera(prop_set={'width':320, 'height': 240})
        frame = self.my_camera.getImage()
        self.timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        file_name = "/tmp/cameraOut" + self.timestamp + ".jpg"
        frame.save(file_name)
        return file_name
