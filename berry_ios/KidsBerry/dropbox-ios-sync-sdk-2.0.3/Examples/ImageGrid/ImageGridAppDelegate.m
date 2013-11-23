#import "ImageGridSettingsController.h"
#import "ImageGridAppDelegate.h"
#import <Dropbox/Dropbox.h>
#import "ImageGridViewController.h"

@interface ImageGridAppDelegate ()

@property (nonatomic, retain) UINavigationController *rootController;
@property (nonatomic, retain) SettingsController *settingsController;

@end

@implementation ImageGridAppDelegate

+ (ImageGridAppDelegate *)sharedDelegate {
    return (ImageGridAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    DBAccountManager *accountManager =
    [[DBAccountManager alloc] initWithAppKey:@"65ubpjjgow0mh5h" secret:@"6v2ne35ltz9ymv9"];
    [DBAccountManager setSharedManager:accountManager];

    _settingsController = [[ImageGridSettingsController alloc] init];

    DBAccount *account = [accountManager.linkedAccounts objectAtIndex:0];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:_settingsController];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        ImageGridViewController *gridViewController =
        [[ImageGridViewController alloc] initWithFilesystem:filesystem root:[DBPath root]];
        [nav pushViewController:gridViewController animated:NO];
    }
    self.rootController = nav;

    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        ImageGridViewController *gridViewController =
        [[ImageGridViewController alloc] initWithFilesystem:filesystem root:[DBPath root]];
        [self.rootController pushViewController:gridViewController animated:YES];
    }

    return YES;
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

@end
