#import "NotesSettingsController.h"
#import "NotesFolderListController.h"

@implementation NotesSettingsController


- (void)showDataForAccount:(DBAccount*)account fileSystem:(DBFilesystem*)filesystem {
    NotesFolderListController *controller =
    [[NotesFolderListController alloc]
     initWithFilesystem:filesystem root:[DBPath root]];
    [self.navigationController pushViewController:controller animated:YES];
}


@end
