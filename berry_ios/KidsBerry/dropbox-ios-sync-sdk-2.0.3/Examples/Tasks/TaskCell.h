#import <UIKit/UIKit.h>

@interface TaskCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *taskLabel;
@property (nonatomic, retain) IBOutlet UIView *taskCompletedView;

@end
