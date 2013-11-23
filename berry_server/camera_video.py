from datetime import datetime
from subprocess import call
from SimpleCV import Camera, VideoStream, Color, Display
import time

class CameraVideo(object):

    def __init__(self):
        self.my_camera = Camera(prop_set={'width': 320, 'height': 240})
        self.live_preview = False
        self.timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

    def start_live_preview(self):
        if self.live_preview is False:
            self.file_name = "cameraOut" + self.timestamp + ".avi"
            self.started_live_preview = True
            video_stream = VideoStream(self.file_name, fps=15)

        while self.live_preview is True:
            #image = my_camera.getImage()
            #image = image.edges()
            #video_stream.writeFrame(image)
            self.my_camera.getImage().save(video_stream)
            time.sleep(0.1)


    def stop_live_preview(self):
        self.live_preview = False
        # construct the encoding arguments
        outname = self.file_name.replace('.avi', '.mp4')
        params = " -i {0} {1}".format(self.file_name, outname)
        # run ffmpeg to compress your video.
        call('ffmpeg' + params, shell=True)
        return outname

    def take_video(self, duration):
       pass
