#import <Dropbox/Dropbox.h>

#import "AppDelegate.h"
#import "HelloViewController.h"

#define APP_KEY     @"p78hpiyefxd4p9z"
#define APP_SECRET  @"hwjzoa1qoxjoqft"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc]
                   initWithFrame:[[UIScreen mainScreen] bounds]];

    /*
     * Create a DBAccountManager object. This object lets you link to a Dropbox
     * user's account which is the first step to working with data on their
     * behalf.
     */

    DBAccountManager* accountMgr = [[DBAccountManager alloc]
                                        initWithAppKey:APP_KEY
                                                secret:APP_SECRET];
    [DBAccountManager setSharedManager:accountMgr];

    HelloViewController *helloController = [HelloViewController new];

    self.window.rootViewController = helloController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    /*
     * Skip directly to test if user has already linked their account
     */

    if (accountMgr.linkedAccount) {
        [self doDropboxTestWithAccount:accountMgr.linkedAccount];
    }

    return YES;
}


/*
 * You'll need to handle requests sent to your app from the linking dialog
 */

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        NSLog(@"App linked successfully!");

        [self doDropboxTestWithAccount:account];

        return YES;
    }
    return NO;
}


/*
 * Runs a simple test using Sync API and writes result to view
 *
 * Steps in test:
 * - Lists the contents of the app folder
 * - Writes test file if it doesn't already exist
 * - Reads contents of test file
 */

- (BOOL)doDropboxTestWithAccount:(DBAccount *)account
{
    NSString *const TEST_DATA = @"Hello Dropbox";
    NSString *const TEST_FILE_NAME = @"hello_dropbox.txt";

    HelloViewController *controller = (HelloViewController *)self.window.rootViewController;
    [controller addTextView];

    DBError *error = nil;

    [controller append:[NSString stringWithFormat:@"Dropbox Sync API Version %@\n\n", kDBSDKVersion]];

    /*
     * Check that we're given a linked account.
     */

    if (!account || !account.linked) {
        [controller append:@"No account linked\n"];
        return NO;
    }

    /*
     * Check if shared filesystem already exists - can't create more than
     * one DBFilesystem on the same account.
     */

    DBFilesystem *filesystem = [DBFilesystem sharedFilesystem];

    if (!filesystem) {
        filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    /*
     * Read contents of Dropbox app folder
     */

    [controller append:@"Contents of app folder:\n"];

    NSArray *contents = [filesystem listFolder:[DBPath root] error:&error];
    if (!contents)
        return [self printError:error withMessage:@"\nError listing root folder."];

    for (DBFileInfo *info in contents) {
        NSString *fileInfoLine = [NSString stringWithFormat:@"    %@, %@\n",
                                  info.path, info.modifiedTime];
        [controller append: fileInfoLine];
    }

    /*
     * Check if our test file already exists.
     */

    DBPath *path = [[DBPath root] childPath:TEST_FILE_NAME];

    if (![filesystem fileInfoForPath:path error:&error]) { /* see if path exists */

        /*
         * Report error if path look up failed for some other reason than NOT FOUND
         */

        if ([error code] != DBErrorParamsNotFound)
            return [self printError:error atPath:path withMessage:@"Error getting file info."];

        /*
         * Write a new test file.
         */

        DBFile *file = [[DBFilesystem sharedFilesystem] createFile:path error:&error];
        if (!file)
            return [self printError:error atPath:path withMessage:@"Error creating file."];

        if (![file writeString:TEST_DATA error:&error])
            return [self printError:error atPath:path withMessage:@"Error writing file."];
        [file close];
        [controller append:[NSString stringWithFormat:@"Created new file %@.\n", [path stringValue]]];
    }

    /*
     * Read and print the contents of test file.  Since we're not making
     * any attempt to wait for the latest version, this may print an
     * older cached version.  Use status property of DBFile and/or a
     * listener to check for a new version.
     */

    DBFileInfo *info = [filesystem fileInfoForPath:path error:&error];
    if (!info)
        return [self printError:error atPath:path withMessage:@"File does not exist."];

    if ([info isFolder]) {
        [controller append:[NSString stringWithFormat:@"\n%@ is a folder.\n", [path stringValue]]];
    } else {
        DBFile *file = [[DBFilesystem sharedFilesystem] openFile:path error:&error];
        if (!file)
            return [self printError:error atPath:path withMessage:@"Error opening file."];

        NSString *fileContents = [file readString:&error];
        if (!fileContents)
            return [self printError:error atPath:path withMessage:@"Error reading file."];
        [file close];
        [controller append:[NSString stringWithFormat:@"\nRead file %@ and got data:\n    %@",
                               [path stringValue], fileContents]];
    }

    return YES;
}

- (BOOL)printError:(DBError *)error withMessage:(NSString *)message
{
    return [self printError:error atPath:nil withMessage:message];
}

- (BOOL)printError:(DBError *)error atPath:(DBPath *)path withMessage:(NSString *)message
{
    HelloViewController *controller = (HelloViewController *)self.window.rootViewController;
    [controller append:[NSString stringWithFormat:@"\n%@\n", message]];
    if (path) {
        [controller append:[NSString stringWithFormat:@"\tPath: %@\n", path]];
    }
    NSString *reason = [error description];
    [controller append:[NSString stringWithFormat:@"\tReason: %@\n", reason]];
    return NO;
}

@end
