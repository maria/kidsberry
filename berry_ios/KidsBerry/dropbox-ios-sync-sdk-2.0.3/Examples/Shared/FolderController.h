#import <Foundation/Foundation.h>
@class DBAccount, DBFilesystem, DBPath;
@protocol FolderController <NSObject>
- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root;

@property (nonatomic, readonly) DBAccount *account;

@end
