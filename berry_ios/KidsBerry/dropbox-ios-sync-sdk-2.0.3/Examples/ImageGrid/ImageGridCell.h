#import <UIKit/UIKit.h>

@interface ImageGridCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic) CGFloat progress;
@property (nonatomic, weak) UILabel *syncStatusLabel;


@end
