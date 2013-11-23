#import <UIKit/UIKit.h>

@class DBFilesystem;


@interface NotesAppDelegate : UIResponder <UIApplicationDelegate>

+ (NotesAppDelegate *)sharedDelegate;

@property (strong, nonatomic) UIWindow *window;

@end
