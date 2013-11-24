from datetime import datetime
from subprocess import call
from SimpleCV import Camera, VideoStream, Color, Display
from time import sleep

class CameraVideo(object):

    def __init__(self):
        if hasattr(self, 'my_camera') is False:
            self.my_camera = Camera(prop_set={'width': 320, 'height': 240})
        self.my_display = Display(resolution=(320, 240))
        self.live_preview = False
        self.timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

    def start_live_preview(self):
        if self.live_preview is False:
            self.file_name = "/tmp/cameraOut" + self.timestamp + ".avi"
            self.live_preview = True
            video_stream = VideoStream(self.file_name, fps=15)
        framecount = 0
        while self.live_preview is True:
        #while self.live_preview is True:
            #image = my_camera.getImage()
            #image = image.edges()
            #video_stream.writeFrame(image)
            self.my_camera.getImage().save(self.my_display)
            sleep(0.1)


    def stop_live_preview(self):
        self.live_preview = False
        # construct the encoding arguments
        # outname = self.file_name.replace('.avi', '.mp4')
        # params = " -i {0} {1}".format(self.file_name, outname)
        # run ffmpeg to compress your video.
        # call('ffmpeg' + params, shell=True

    def take_video(self, duration):
       pass
