import dropbox
import json

from settings_local import DROPBOX_API_KEY, DROPBOX_API_SECRET


class DropboxClient(object):

    def __init__(self, access_token=None, app_key=DROPBOX_API_KEY, app_secret=DROPBOX_API_SECRET):
        """Start a OAuth flow to get the user access_token in order to initialize
        the client.
        """
        access_token = 'Itc3XCDTtjUAAAAAAAAAAV9vCu1EjF_UI0vcmQhSotu16taCxvffLhYKzC6frMTS'
        if not access_token:
            self.flow = dropbox.client.DropboxOAuth2FlowNoRedirect(app_key, app_secret)
            authorize_url = self.flow.start()
            print("Go to ", authorize_url)
            print("Introduce authorization code:")
            authorization_code = raw_input().strip()
            access_token, user_id = self.flow.finish(authorization_code)
        self.client = dropbox.client.DropboxClient(access_token)


    def upload(self, filename):
        """Upload a file to the Dropbox, return the response."""
        with open(filename, 'r') as file:
            response = self.client.put_file(filename, file)
        return response


    def download(self, filename):
        """Download the file from Dropbox and save the file on the localhost,
        with the same name and content.
        """
        try:
            dropbox_file = self.client.get_file(filename)
        except Exception:
            raise("There was an error downloading the file!")

        with open(filename, 'rw') as local_file:
            local_file.write(dropbox_file.read())
        return local_file
