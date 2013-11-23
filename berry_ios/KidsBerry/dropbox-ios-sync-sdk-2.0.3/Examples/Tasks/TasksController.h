#import <UIKit/UIKit.h>

@interface TasksController : UITableViewController

- (IBAction)didPressLink;
- (IBAction)didPressUnlink;

@property (nonatomic, retain) IBOutlet UIView *headerView;

@end
