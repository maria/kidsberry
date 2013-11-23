from SimpleCV import Camera, VideoStream, Color, Display
from time import sleep
from datetime import datetime

class CameraVideo(object):
    def __init__(self):
        self.my_camera = Camera(prop_set={'width': 320, 'height': 240})
        self.outname = 'output.mp4'
        self.live_preview = 0
        self.timestamp = datetime.now().strftime('%Y%m%d%H%M%S')


    def start_live_preview(self):
        if (self.live_preview == False):
            self.file_name = file_name = "cameraOut" + self.timestamp + ".avi"
            self.started_live_preview = True
            video_stream = VideoStream(self.file_name)
        while self.live_previw == True:
            image = my_camera.getImage()
            image = image.edges()
            # write the frame
            video_stream.writeFrame(image)


    def stop_live_preview(self):
        self.live_preview = False
        # construct the encoding arguments
        params = " -i {0} {1}".format(self.file_name, outname)
        # run ffmpeg to compress your video.
        call('ffmpeg' + params, shell=True)
        return self.file_name
