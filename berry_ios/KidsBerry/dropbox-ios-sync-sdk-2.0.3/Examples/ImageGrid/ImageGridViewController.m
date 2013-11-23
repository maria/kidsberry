#import "ImageGridViewController.h"
#import <Dropbox/Dropbox.h>
#import "ImageGridCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
@interface ImageGridViewController ()
@property (nonatomic, strong) DBFilesystem *filesystem;
@property (nonatomic, strong) DBPath *root;
@property (nonatomic) BOOL loadingFiles;
@property (nonatomic) BOOL needToLoadFiles;
@property (nonatomic, strong) NSMutableDictionary *contents;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) NSString *editingFileName;
@property (nonatomic) BOOL viewHasAppeared;
@property (nonatomic, weak) CAGradientLayer *background;
@end

@implementation ImageGridViewController
@synthesize account;
static NSString *kCellIdentifier = @"GridCell";
static CGFloat const kCellSpacing = 5;
static CGFloat const kGridCellCount = 9;
static CGSize const kPortraitCellSize = {94, 94};
static CGSize const kLandscapeCellSize = {105, 105};
static UIEdgeInsets const kGridEdgeInsets = {10, 10, 10, 10};

static NSSet *filenames;

+ (void)initialize
{
    filenames = [NSSet setWithArray:@[@"0.png", @"1.png", @"2.png", @"3.png", @"4.png",
                 @"5.png", @"6.png", @"7.png", @"8.png"]];
}

- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root
{
    if (!(self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]])) return nil;
    self.filesystem = filesystem;
    self.root = root;
    self.library = [[ALAssetsLibrary alloc] init];
    self.title = NSLocalizedString(@"Image Grid", @"");
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.viewHasAppeared){
        __weak id weakSelf = self;
        [self.filesystem addObserver:self forPathAndChildren:self.root block:^{
            [weakSelf loadFiles];
        }];
        [self loadFiles];
        self.viewHasAppeared = YES;
    }
}

// Set up a pleasant blue gradient background for the CollectionView
- (void)configureViewAppearance
{
    CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
    gradient.frame = self.collectionView.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:42.0/255.0 green:148.0/255.0 blue:236.0/255.0 alpha:1].CGColor,
                        (id)[UIColor colorWithRed:0.0/255.0 green:118.0/255.0 blue:215.0/255.0 alpha:1].CGColor];
    gradient.locations = @[@0, @1];

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.collectionView.backgroundView = backgroundView;
    [backgroundView.layer addSublayer:gradient];
    self.background = gradient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.collectionView registerClass:[ImageGridCell class] forCellWithReuseIdentifier:kCellIdentifier];
    [self configureViewAppearance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

# pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    self.editingFileName = [NSString stringWithFormat:@"%i.png", indexPath.row];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

# pragma mark UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return kGridCellCount;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.imageView.image = nil;

    NSString *fileNameString = [NSString stringWithFormat:@"%i.png", indexPath.row];
    DBFile *file = self.contents[fileNameString];
    cell.syncStatusLabel.text = @"";
    cell.progress = -1;
    if (!file){
        cell.syncStatusLabel.text = NSLocalizedString(@"Empty", nil);
        cell.backgroundColor = [UIColor colorWithRed:71.0/255.0 green:158.0/255.0 blue:233.0/255.0 alpha:1];
    } else {
        cell.backgroundColor = [UIColor clearColor];
        DBFileStatus *fileStatus = file.status;
        DBFileStatus *newerStatus = file.newerStatus;
        if (fileStatus.cached){
            // There is local image data to display in this cell
            cell.imageView.image = [UIImage imageWithData:[file readData:nil]];
        }
        if (fileStatus.state == DBFileStateUploading){
            cell.syncStatusLabel.text = NSLocalizedString(@"Uploading", nil);
            cell.progress = file.status.progress;
        } else if (fileStatus.state == DBFileStateDownloading){
            cell.syncStatusLabel.text = NSLocalizedString(@"Downloading", nil);
            cell.progress = file.status.progress;
        } else if (newerStatus && file.newerStatus.state == DBFileStateDownloading){
            cell.syncStatusLabel.text = NSLocalizedString(@"Updating", nil);
            cell.progress = file.newerStatus.progress;
        }
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        return kPortraitCellSize;
    } else {
        return kLandscapeCellSize;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return kGridEdgeInsets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kCellSpacing;
}

# pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    NSURL *assetURL = info[UIImagePickerControllerReferenceURL];
    [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
        DBFile *file = self.contents[self.editingFileName];
        if (file == nil || [file isThumb]) {
            if (file == nil) {
                // Create a new file and add it to the set of files
                // being observed
                DBPath *path = [self.root childPath:self.editingFileName];
                file = [self.filesystem createFile:path error:nil];
            } else if ([file isThumb]) {
                // Need to open the real contents in order to edit.
                DBFile *full = [self.filesystem openFile:[[file info] path] error:nil];
                [file close];
                file = full;
            }

            // Update state and observer for the new DBFile object.
            __weak id weakSelf = self;
            __weak DBFile *weakFile = file;
            self.contents[self.editingFileName] = file;
            [file addObserver:self block:^{
                [weakSelf reloadCellForFile:weakFile];
            }];
        }

        // Write a thumbnail sized PNG to this file
        [file writeData:UIImagePNGRepresentation(thumbnail) error:nil];

    } failureBlock:^(NSError *error) {
        NSLog(@"error reading file");
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark rotation

// So rotation animation looks nice
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.collectionView performBatchUpdates:nil completion:nil];
    self.background.frame = self.background.superlayer.bounds;
}

# pragma mark private methods

// Convert a file name like "3.png" into an indexpath
// with section 0, row 3
- (NSIndexPath*)indexPathForFileName:(NSString*)filename
{
    return [NSIndexPath indexPathForRow:[[filename stringByDeletingPathExtension] intValue] inSection:0];
}

// Lists the files in the root directory of this controlller, finds as many files named "0.png" -
// "8.png" as there are in the directory. Registers observer callbacks on all new files and
// removes deleted files from the set of open DBFiles managed by this controller
- (void)loadFiles
{
    self.needToLoadFiles = YES;
    if (self.loadingFiles) {
        // Currently loading files. loadFiles will be called again once
        // files are loaded
        return;
    }
    self.loadingFiles = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        self.needToLoadFiles = NO;
        NSArray *fileInfos = [_filesystem listFolder:_root error:nil];
        NSIndexSet *pngIndices = [fileInfos indexesOfObjectsPassingTest:^BOOL(DBFileInfo* obj, NSUInteger idx, BOOL *stop) {
            // This loop picks out the files with the names "0.png" through "8.png" - the image files
            // which are shown on the grid
            NSString *filename = obj.path.name;
            BOOL found = [filenames containsObject:filename];
            return found;
        }];
        fileInfos = [[fileInfos objectsAtIndexes:pngIndices] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"path.name" ascending:YES]]];

        dispatch_async(dispatch_get_main_queue(), ^() {
            // This will merge the last set of DBFile objects with the latest
            // data from the filesystem and the final contents of self.contents
            // will be a mapping of file names to DBFile objects representing
            // the files in this controller's "root" folder.
            NSMutableDictionary *newContents = [NSMutableDictionary dictionary];
            NSMutableArray *indexesToReload = [NSMutableArray array];
            for (DBFileInfo *fileInfo in fileInfos){
                NSString *fileName = fileInfo.path.name;
                DBFile *previouslyOpenedFile = [self.contents objectForKey:fileName];
                if (previouslyOpenedFile){
                    // Keep the previous DBFile object in the new contents
                    // collection
                    [newContents setObject:previouslyOpenedFile forKey:fileName];
                    [self.contents removeObjectForKey:fileName];
                } else {
                    // This file has been added to the folder since last time
                    // loadFiles was called.
                    // Open a thumbnail of the file if available, otherwise
                    // open the full file.
                    DBFile *file = nil;
                    if (fileInfo.thumbExists) {
                        // This thumb size is arguably larger than we need, but
                        // gives a clearer image, and a better demonstration of
                        // download progress.
                        file = [self.filesystem openThumbnail:fileInfo.path
                                                       ofSize:DBThumbSizeL
                                                     inFormat:DBThumbFormatPNG
                                                        error:nil];
                    } else {
                        // This case is triggered primarily when the file is
                        // modified locally, and therefore cached.
                        file = [self.filesystem openFile:fileInfo.path error:nil];
                    }
                    [newContents setObject:file forKey:fileName];
                    __weak id weakFile = file;
                    __weak id weakSelf = self;
                    [file addObserver:self block:^{
                        [weakSelf reloadCellForFile:weakFile];
                    }];
                    [indexesToReload addObject:[self indexPathForFileName:fileName]];
                }
            }
            for (NSString *deletedFileName in [self.contents allKeys]){
                // These filenames were in the folder before but are not
                // in the folder as of the last call to listFolder:error:
                [indexesToReload addObject:[self indexPathForFileName:deletedFileName]];
            }
            self.contents = newContents;
            if (indexesToReload.count > 0){
                // Reload all of the cells where a file has changed, been added
                // or deleted
                [self.collectionView reloadItemsAtIndexPaths:indexesToReload];
            }
            self.loadingFiles = NO;
            if (self.needToLoadFiles){
                // needToLoadFiles is YES if an update callback happened
                // during a previous call to loadFiles
                [self loadFiles];
            }
        });
    });
}

// Reloads the cell displaying the image stored in a particular file.
// Updates can be to reflect progress in upload, download or update,
// or to change the image visible in a cell once an update or download
// is complete
- (void)reloadCellForFile:(DBFile*)file
{
    if ([file newerStatus].cached){
        // Update when the newer version of the file is cached
        [file update:nil];
    }
    [[self collectionView] reloadItemsAtIndexPaths:@[[self indexPathForFileName:file.info.path.name]]];
}

@end
