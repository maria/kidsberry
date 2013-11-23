#import "ImageGridCell.h"
#import <QuartzCore/QuartzCore.h>
#import "Util.h"


@interface ImageGridCell ()

@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) CAGradientLayer *gradientLayer;
@property (nonatomic, weak) UIView *highlightView;
@end

@implementation ImageGridCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:imageView];
        self.imageView = imageView;
        self.imageView.layer.borderColor = [UIColor colorWithWhite:.9 alpha:1].CGColor;
        self.imageView.layer.borderWidth = 3;

        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.contentView addSubview:progressView];
        progressView.hidden = YES;
        self.progressView = progressView;
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, frame.size.width, 20)];
        statusLabel.textAlignment = DBX_ALIGN_CENTER;
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textColor = [UIColor whiteColor];
        statusLabel.font = [UIFont systemFontOfSize:12.f];
        CAGradientLayer *layer = [[CAGradientLayer alloc] init];
        layer.colors = @[(id)[UIColor colorWithWhite:.2 alpha:.8].CGColor, (id)[UIColor clearColor].CGColor];
        layer.locations = @[@0, @1];

        self.syncStatusLabel = statusLabel;
        self.gradientLayer = layer;
        [self.contentView.layer addSublayer:layer];
        [self.contentView addSubview:statusLabel];

        UIView *highlightView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        highlightView.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
        highlightView.alpha = 0;
        self.highlightView = highlightView;
        [self.contentView addSubview:highlightView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;

    self.progressView.frame = CGRectMake(5, self.contentView.bounds.size.height - 10, self.contentView.bounds.size.width - 10, 5);
    CGRect statusViewFrame = self.syncStatusLabel.frame;
    statusViewFrame.size.width = self.contentView.bounds.size.width;
    self.syncStatusLabel.frame = statusViewFrame;
    self.gradientLayer.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 26);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.highlightView.alpha = highlighted ? 1 : 0;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    if (_progress >= 0 && _progress <= 1){
        self.progressView.hidden = NO;
        self.progressView.progress = progress;
    } else {
        self.progressView.hidden = YES;
    }
}

@end
