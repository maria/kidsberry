#import <Dropbox/Dropbox.h>
#import "ImageGridSettingsController.h"
#import "ImageGridViewController.h"

@interface ImageGridSettingsController ()

@end

@implementation ImageGridSettingsController

- (void)showDataForAccount:(DBAccount*)account fileSystem:(DBFilesystem*)filesystem {
    ImageGridViewController *controller =
    [[ImageGridViewController alloc]
     initWithFilesystem:filesystem root:[DBPath root]];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
