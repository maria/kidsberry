#import "AppDelegate.h"
#import <Dropbox/Dropbox.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    DBAccountManager *mgr =
        [[DBAccountManager alloc] initWithAppKey:@"xoit9j3uwj9vmdv" secret:@"dkc3edahiij64jl"];
    [DBAccountManager setSharedManager:mgr];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    UIViewController *root = [storyboard instantiateInitialViewController];
    self.window.rootViewController = root;

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    [[DBAccountManager sharedManager] handleOpenURL:url];

    return YES;
}

@end
