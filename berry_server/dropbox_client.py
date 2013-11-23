import dropbox
import json

from settings_local import DROPBOX_API_KEY, DROPBOX_API_SECRET


class DropboxClient(object):

    def __init__(self, access_token, app_key=DROPBOX_API_KEY, app_secret=DROPBOX_API_SECRET):
        """Start a OAuth flow to get the user access_token in order to initialize
        the client.
        TODO: Move this on the client side.
        """
        self.client = dropbox.client.DropboxClient(access_token)


    def upload(self, filename):
        """Upload a file to the Dropbox, return the response."""
        with open(filename, 'r') as file:
            response = self.client.put_file(filename, file)
        return json.loads(response)


    def download(self, filename):
        """Download the file from Dropbox and save the file on the localhost,
        with the same name and content.
        """
        dropbox_file, metadata = self.client.get_file_and_metadata(filename)
        with open(filename, 'rw') as local_file:
            local_file.write(dropbox_file.read())
        return metadata
