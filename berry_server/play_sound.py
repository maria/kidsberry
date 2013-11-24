import pygame.mixer
from time import sleep

class PlaySounds(object):
    def __init__(self):
        pygame.mixer.init(48000, -16, 1, 1024)
        self.channel = pygame.mixer.Channel(1)

    def play_sound(self, file_name='/home/pi/kidsberry/berry_server/WilhelmScream.wav'):
        sound = pygame.mixer.Sound(file_name)
        self.channel.play(sound)
        sleep(2.0)
