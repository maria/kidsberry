import dropbox

from settings_local import DROPBOX_API_KEY, DROPBOX_API_SECRET


class DropboxClient(object):

    def __init__(self, access_token, app_key=DROPBOX_API_KEY, app_secret=DROPBOX_API_SECRET):
        """Start a OAuth flow to get the user access_token in order to initialize
        the client.
        TODO: Move this on the client side.
        """
        self.flow = dropbox.client.DropboxOAuth2FlowNoRedirect(app_key, app_secret)
        authorize_url = self.flow.start()
        print("Go to ", authorize_url)
        print("Introduce authorization code:")
        authorization_code = raw_input().strip()
        access_token, user_id = self.flow.finish(authorization_code)

        self.client = dropbox.client.DropboxClient(access_token)
