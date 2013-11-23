from SimpleCV import Camera
from time import sleep
from datetime import datetime

myCamera = Camera(prop_set={'width':320, 'height': 240})
timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

class CameraPicture:

	def takePicture(self):
		frame = myCamera.getImage()
		fileName = "cameraOut" + timestamp + ".jpg"
		frame.save(filename)
		return filename
	
