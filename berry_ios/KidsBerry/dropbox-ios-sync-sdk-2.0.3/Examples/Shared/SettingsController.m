#import "SettingsController.h"
#import "Util.h"
#import "FolderController.h"

typedef enum {
    LinkRow,
    UnlinkRow,
    AccountRow
} RowType;

@interface SettingsController ()

@property (nonatomic, readonly) DBAccountManager *manager;
@property (nonatomic, copy) void(^navigationBlock)() ;

@end


@implementation SettingsController

- (id)initWithNavigationBlock:(void (^)())navigationBlock
{
    if (!(self = [super initWithStyle:UITableViewStyleGrouped])) return nil;

    self.title = @"Settings";
    self.navigationBlock = navigationBlock;

    __weak SettingsController *weakSelf = self;

    [self.manager addObserver:self block: ^(DBAccount *account) {
        [weakSelf accountUpdated:account];
    }];

    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [self initWithNavigationBlock:nil];
}

- (id)init {
   return [self initWithNavigationBlock:nil];
}

- (void)dealloc {
    [self.manager removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.manager.linkedAccounts count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == (NSInteger)[self.manager.linkedAccounts count] ? 1 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc]
                 initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }

    cell.textLabel.textAlignment = DBX_ALIGN_CENTER;
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch ([self rowTypeForIndexPath:indexPath]) {
        case AccountRow: {
            NSString *text = @"Dropbox";
            DBAccountInfo *info = [self accountForSection:[indexPath section]].info;
            if (info) {
                text = info.displayName;
            }

            cell.textLabel.text = text;
            cell.textLabel.textAlignment = DBX_ALIGN_LEFT;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case LinkRow:
            cell.textLabel.text = @"Link";
            break;
        case UnlinkRow:
            cell.textLabel.text = @"Unlink";
            break;
    }

    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self rowTypeForIndexPath:indexPath]) {
        case AccountRow: {
            DBAccount *account = [self accountForSection:[indexPath section]];
            DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
            [self showDataForAccount:account fileSystem:filesystem];
            break;
        }
        case LinkRow:
            [self didPressAdd];
            break;
        case UnlinkRow:
            [[self accountForSection:[indexPath section]] unlink];
            break;
    }
}

- (void)showDataForAccount:(DBAccount *)account fileSystem:(DBFilesystem *)filesystem
{
    // Override in subclass
}

- (void)didPressAdd {
    [self.manager linkFromController:self.navigationController];
}


#pragma mark - private methods

- (DBAccountManager *)manager {
    return [DBAccountManager sharedManager];
}

- (void)reload {
    [self.tableView reloadData];
}

- (void)accountUpdated:(DBAccount *)account {
    if (!account.linked && [self.currentAccount isEqual:account]) {
        [self.navigationController popToViewController:self animated:YES];
        Alert(@"Your account was unlinked!", nil);
/*  } else if (!account.linked && [_accounts containsObject:account]) {
        NSInteger index = [_accounts indexOfObject:account];
        [_accounts removeObjectAtIndex:index];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
 */
    } else {
        [self reload];
    }
}

- (DBAccount *)accountForSection:(NSInteger)section {
    return [self.manager.linkedAccounts objectAtIndex:section];
}

- (DBAccount *)currentAccount {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if ([viewControllers count] < 2) return nil;

    id<FolderController> folderController =
        (id<FolderController>)[viewControllers objectAtIndex:1];
    return folderController.account;
}

- (RowType)rowTypeForIndexPath:(NSIndexPath *)indexPath {
    NSArray *linkedAccounts = self.manager.linkedAccounts;
    if (!linkedAccounts || [indexPath section] == (NSInteger)[linkedAccounts count]) {
        return LinkRow;
    } else if ([indexPath row] == 1) {
        return UnlinkRow;
    } else {
        return AccountRow;
    }
}

@end
