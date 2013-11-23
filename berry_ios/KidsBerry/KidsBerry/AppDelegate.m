//
//  AppDelegate.m
//  KidsBerry
//
//  Created by Loredana Albulescu on 11/23/13.
//  Copyright (c) 2013 Loredana Albulescu. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "SBJSON.h"
#import "AppDelegate.h"
#import "HelloViewController.h"


#define APP_KEY         @"4by5wti9t2dktp2"
#define APP_SECRET      @"2xzsio5vcvjjcya"
#define SERVER_IP       @"172.28.100.228:5000"
#define SERVER_HOSTNAME @"http:172.28.100.228/login"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


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
    
    
    if (accountMgr.linkedAccount) {
        [self doDropboxTestWithAccount:accountMgr.linkedAccount];
    }
     */
    return YES;
}


/*
 * You'll need to handle requests sent to your app from the linking dialog
 */

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation
{
   
    /*
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
     
    if (account) {
        NSLog(@"App linked successfully!");
        
        [self doDropboxTestWithAccount:account];
        
        return YES;
    }
     */
    NSString *dropboxUsername=[ NSString stringWithFormat:@"loredanaalbulescu"];
    [[DBAccountManager sharedManager] handleOpenURL:url];
    //[self sendToServerDropboxUsername:dropboxUsername];
    [self receiveDataFromServer];
    return YES;
    
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



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) sendToServerDropboxUsername:(NSString *)username
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_HOSTNAME]];
    [request setHTTPMethod:@"POST"];
    
    NSError *error = nil;
    
    //NSDictionary *jsonDictionary = @{ @"username" :username };
    NSDictionary* jsonDictionary = [NSDictionary dictionaryWithObject:username
                                                              forKey:@"username"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (jsonData) {
        NSLog(@"Sending data to server: %@", jsonData);
        [request setHTTPBody:jsonData];
    } else {
        NSLog(@"Unable to serialize the data %@: %@", jsonDictionary, error);
    }
}

//method which receive data from server
-(void) receiveDataFromServer
{
    NSString *url= [NSString stringWithFormat:@"http:172.28.100.228/"];
                           
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        [self performSelectorOnMainThread:@selector(fetchedData:)
                               withObject:data waitUntilDone:YES];
    });
}

//parse out the json receive from server
-(void) fetchedData:(NSData*) responseData{
    NSError* error;
    NSArray* json = [NSJSONSerialization
                     JSONObjectWithData:responseData
                     options:kNilOptions
                     error:&error];
    NSLog(@"Json received from server %@",json);
}



@end
