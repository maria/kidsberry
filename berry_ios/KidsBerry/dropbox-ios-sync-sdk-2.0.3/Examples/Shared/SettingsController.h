#import <Dropbox/Dropbox.h>
#import <UIKit/UIKit.h>

@interface SettingsController : UITableViewController
- (void)showDataForAccount:(DBAccount*)account fileSystem:(DBFilesystem*)filesystem;

@end
