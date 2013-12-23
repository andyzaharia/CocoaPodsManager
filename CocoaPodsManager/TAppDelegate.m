//
//  TAppDelegate.m
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "TAppDelegate.h"

#import "CocoaPodWindowController.h"
#import "NSCustomImageView.h"
#import "ProjectTableView.h"
#import "NSString+Misc.h"
#import "AppConstants.h"
#import "CPProject.h"


@interface TAppDelegate () <NSTableViewDataSource, NSTableViewDelegate, PodManagerDelegate>
{
    
}

@property (assign) IBOutlet       NSCustomImageView           *ivProject;
@property (assign) IBOutlet       ProjectTableView            *recentlyUsedProjects;

@property (assign) IBOutlet       NSTextField                 *lbVersionText;
@property (assign) IBOutlet       NSMenuItem                  *openRecentMenu;

@property (nonatomic, retain)   NSMutableArray              *viewControllers;
@property (nonatomic, retain)   NSArray                     *projects; // Used for recents

@end

@implementation TAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSPersistentStoreCoordinator setDataModelName:@"DataModel"];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object: nil];
    
    __weak  TAppDelegate *weakSelf = self;
    [self.ivProject registerForDraggedTypes:@[(NSString*)kUTTypeFileURL, NSFilenamesPboardType]];
    [self.ivProject setOnFileDropBlock: ^(NSString *filePath){
        [(TAppDelegate *)weakSelf openFile: filePath];
    }];
    
    [self.recentlyUsedProjects setTarget: self];
    [self.recentlyUsedProjects setDoubleAction:@selector(tableViewDoubleClick:)];
    
    [self refreshRecentProjectsList];
    
    if ([PodSpec findAll].count == 0) {
        [self updatePodList: nil];
    }
    [self getCocoaPodVersion];
        
    [self updatePodsProperties];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(backgroundContextDidSave:)
                                                 name: NSManagedObjectContextDidSaveNotification
                                               object: nil];
    
    self.viewControllers = [NSMutableArray array];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
    return YES;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [self openFile: filename];
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[PodRepositoryManager sharedPodSpecManager] cancelUpdate];
}

#pragma mark -

-(void) openFile: (NSString *) filename
{
    CocoaPodWindowController *controller = [[CocoaPodWindowController alloc] initWithWindowNibName:@"CocoaPodWindowController"];
    [controller openFile: filename];
    [controller showWindow: self];
    
    [self.viewControllers addObject: controller];
    [self refreshRecentProjectsList];
}

-(void) windowWillClose: (NSNotification *) notification
{
    NSWindow *window = [notification object];
    for (CocoaPodWindowController *controller in self.viewControllers) {
        if (controller.window == window) {
            if (controller.canClose) {
                [self.viewControllers removeObject: controller];
                break;
            }
        }
    }
}

-(void) updatePodsProperties
{
    [self.lbStatus setStringValue:@""];
    
    [self.loadingIndicator startAnimation: self];
    
    __weak TAppDelegate *weakSelf = self;
    PodRepositoryManager *manager = [PodRepositoryManager sharedPodSpecManager];
    manager.delegate = self;
    [manager updateAllPodProperties:^{
        [weakSelf.loadingIndicator stopAnimation: weakSelf];
    }];
}

-(void) getCocoaPodVersion
{
    NSString *currentVersion = @"";
    
    //[self.lbVersionText setStringValue:@""];
    
    CocoaPodsApp *app = [CocoaPodsApp sharedCocoaPodsApp];
    if ([app isInstalled]) {
        currentVersion = [app cocoaPodVersion];
    }

    __weak TAppDelegate *weakSelf = self;
    [[CocoaPodsApp sharedCocoaPodsApp] getOnlineVersionFromGithub:^(NSString *version) {
        NSLog(@"Latest version %@", version);
        
        NSInteger lastVersionInt = [[version stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
        NSInteger currentVersionInt = [[currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
        
        if (currentVersionInt < lastVersionInt) {
            // We have a new version available
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *currentVersionStr = PODS_NOT_INSTALLED_LABEL;
                
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString: @"" attributes: nil];
                [string beginEditing];
                
                if ([currentVersion length] > 0) {
                    NSString *removedVersionDots = [version stringByReplacingOccurrencesOfString:@"." withString:@""];
                    currentVersionStr = [NSString stringWithFormat:@"Current version: %@", currentVersion];
                    
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:currentVersionStr]];
                    
                    NSString *changeLogLinkStr = [NSString stringWithFormat:@"%@#%@", CHANGELOG_URL_STR, removedVersionDots];
                    NSURL *changeLogURL = [NSURL URLWithString: changeLogLinkStr];
                    
                    NSString *newVersionLabel = @" New version ";
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString: newVersionLabel]];
                    
                    NSRange hyperLinkRange = NSMakeRange(0, [version length]);

                    NSMutableAttributedString *hyperlinkString = [[NSMutableAttributedString alloc] initWithString: version];
                    [hyperlinkString beginEditing];
                    [hyperlinkString addAttribute:NSLinkAttributeName value:changeLogURL range: hyperLinkRange];
                    [hyperlinkString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range: hyperLinkRange];
                    [hyperlinkString endEditing];

                    [string appendAttributedString: hyperlinkString];
                }else {
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString: PODS_NOT_INSTALLED_LABEL]];
                }
    
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                [paragraphStyle setAlignment: kCTTextAlignmentRight];
                
                NSRange stringRange = NSMakeRange(0, [[string string] length]);
                [string addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range: stringRange];
                [string addAttribute:NSFontAttributeName value:self.lbVersionText.font range: stringRange];
                
                [string endEditing];
                [weakSelf.lbVersionText setAttributedStringValue: string];
            });
        }
    } onError:^(NSError *error) {
        
    }];
}

-(void) refreshRecentProjectsList
{
    NSMutableArray *items = [CPProject findAllSortedBy:@"date" ascending: NO].mutableCopy;
    // Lets check if all projects exists
    __block NSMutableArray *itemsToRemove = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(CPProject *proj, NSUInteger idx, BOOL *stop) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:proj.projectFilePath]) {
            [itemsToRemove addObject: proj];
        }
    }];
    if ([itemsToRemove count]) {
        // Cleanup the missing projects
        [items removeObjectsInArray:itemsToRemove];
        NSManagedObjectContext *context = [NSManagedObjectContext contextForMainThread];
        [itemsToRemove enumerateObjectsUsingBlock:^(CPProject *proj, NSUInteger idx, BOOL *stop) {
            [context deleteObject: proj];
        }];
        if ([context hasChanges]) {
            [context save: nil];
        }
    }
    
    self.projects = items;
    [self.recentlyUsedProjects reloadData];
    
    [self.openRecentMenu.submenu removeAllItems];
    for (CPProject *proj in self.projects) {
        // Cleanup if project name is nil
        if (![proj.name length]) {
            NSManagedObjectContext *context = [NSManagedObjectContext contextForMainThread];
            [context performBlock:^{
                [context deleteObject: proj];
                [context save: nil];
            }];
        } else {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:proj.name action:@selector(openRecentItem:) keyEquivalent: @""];
            item.tag = [self.projects indexOfObject: proj];
            [self.openRecentMenu.submenu addItem: item];
        }
    }
}

-(void) openRecentItem: (NSMenuItem *) sender
{
    CPProject *project = [self.projects objectAtIndex: sender.tag];
    [self openProject: project];
}

- (IBAction)openNewPodDoc:(id)sender {
    
    [self.window orderOut: self];
    
    CocoaPodWindowController *controller = [[CocoaPodWindowController alloc] initWithWindowNibName:@"CocoaPodWindowController"];
    [controller showWindow: self];
    [self.viewControllers addObject: controller];
}

- (IBAction)updatePodList:(id)sender {
    [self updatePodsProperties];
}

- (IBAction)clearPodList:(id)sender {
    [PodSpec deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"name.length > 0"]];
    [self updatePodList: nil];
}

-(void) openProject: (CPProject *) project
{
    // Lets look for already opened Windows
    __block BOOL alreadyOpened = NO;
    __block CocoaPodWindowController *_controller = nil;
    [self.viewControllers enumerateObjectsUsingBlock:^(CocoaPodWindowController *controller, NSUInteger idx, BOOL *stop) {
        if ([controller.project isSameProject: project]) {
            alreadyOpened = YES;
            _controller = controller;
            *stop = YES;
        }
    }];
    
    if (alreadyOpened) {
        [_controller.window makeKeyWindow];
    }else{
        [self.window orderOut: self];
        
        CocoaPodWindowController *controller = [[CocoaPodWindowController alloc] initWithWindowNibName:@"CocoaPodWindowController"];
        [controller openFile: project.projectFilePath];
        [controller showWindow: self];
        [self.viewControllers addObject: controller];
    }
    
    [self refreshRecentProjectsList];
}

#pragma mark - PodManagerDelegate

-(void) podManagerUpdateCompleted: (PodRepositoryManager *)sender
{
    [self.loadingIndicator stopAnimation: self];
    [self.lbStatus setStringValue:@""];
}

-(void) podManager: (PodRepositoryManager *)sender isUpdatingWithProgress: (CGFloat) progress
{
    [self.lbStatus setStringValue:[NSString stringWithFormat:@"Please wait... %2.2f %%", progress * 100]];
}

-(void) podManager: (PodRepositoryManager *)sender didFailedWithError: (NSError *) error
{
    [self.loadingIndicator stopAnimation: self];
    [self.lbStatus setStringValue:[NSString stringWithFormat:@"Error: %@", [error description]]];
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.projects count];
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
    result.backgroundStyle = NSBackgroundStyleRaised;
    
    CPProject *proj = [self.projects objectAtIndex: row];
    
    NSTextField *tf = [result viewWithTag: 1];
    if(tf){
        [tf setStringValue: ([proj.name length]) ? proj.name : @"No name"];
    }
    return result;
}

#pragma mark - Double Click

-(void) tableViewDoubleClick: (id) sender
{
    NSInteger row = [self.recentlyUsedProjects clickedRow];
    if ((row != NSNotFound) && (row > -1)) {
        CPProject *proj = [self.projects objectAtIndex: row];
        [self openProject: proj];
    }
}

#pragma mark - NSTextFieldDelegate

-(BOOL) textField:(NSTextField *) textField  openURL:(NSURL *) anURL
{
    [[NSWorkspace sharedWorkspace] openURL:anURL];
    
    return YES;
}

#pragma mark -

- (void)backgroundContextDidSave:(NSNotification *)notification {
    // Make sure we're on the main thread when updating the main context
//    if (![NSThread isMainThread]) {
//        [self performSelectorOnMainThread:@selector(backgroundContextDidSave:)
//                               withObject:notification
//                            waitUntilDone:YES];
//        return;
//    }
//    // merge in the changes to the main context on the main thread
//    [[NSManagedObjectContext defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

@end
