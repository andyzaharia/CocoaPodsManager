//
//  TAppDelegate.m
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "TAppDelegate.h"
#import "PodSpecManager.h"
#import "CocoaPodWindowController.h"
#import "NSCustomImageView.h"
#import "ProjectTableView.h"
#import "XCodeProject.h"
#import "NSString+Misc.h"
#import "AppConstants.h"
#import "CocoaProject.h"


static NSString *CHANGELOG_URL_STR = @"https://github.com/CocoaPods/CocoaPods/blob/master/CHANGELOG.md";

@interface TAppDelegate () <NSTableViewDataSource, NSTableViewDelegate, PodManagerDelegate>
{
    
}

@property (weak) IBOutlet       NSCustomImageView           *ivProject;
@property (weak) IBOutlet       ProjectTableView            *recentlyUsedProjects;

@property (weak) IBOutlet       NSTextField                 *lbVersionText;
@property (weak) IBOutlet       NSMenuItem                  *openRecentMenu;

@property (nonatomic, strong)   NSMutableArray              *viewControllers;
@property (nonatomic, strong)   NSArray                     *xcodeProjects; // Used for recents

@end

@implementation TAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object: nil];
    
    TAppDelegate *__weak app = self;
    [self.ivProject registerForDraggedTypes:@[(NSString*)kUTTypeFileURL, NSFilenamesPboardType]];
    [self.ivProject setOnFileDropBlock: ^(NSString *filePath){
        [app openFile: filePath];
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
    [MagicalRecord setupCoreDataStack];
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
    [[PodSpecManager sharedPodSpecManager] cancelUpdate];
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
    PodSpecManager *manager = [PodSpecManager sharedPodSpecManager];
    manager.delegate = self;
    [manager updateAllPodProperties];
}

-(void) getCocoaPodVersion
{
    TODO("Clean this.")
    
    NSFont *font = self.lbVersionText.font;
    NSString *currentVersion = @"";
    
    CocoaPodsApp *app = [CocoaPodsApp sharedCocoaPodsApp];
    if ([app isInstalled]) {
        currentVersion = [app cocoaPodVersion];
        
        NSString *lHTML = [NSString stringWithFormat:@"CocoaPods %@",currentVersion];
        NSString *html = [NSString stringWithFormat:@"<div width='100%%' align='right' style=\"font-family:'%@'; font-size:%dpx;\">%@</div>", [font fontName], (int)[font pointSize], lHTML];
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
        [self.lbVersionText setAttributedStringValue: string];
    }else {
        [self.lbVersionText setStringValue: @"Not installed."];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"https://raw.github.com/CocoaPods/Specs/master/CocoaPods-version.yml"];
        NSString *list = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error: NULL];
        if ([list length]) {
            NSMutableArray *lines = [list componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]].mutableCopy;
            if ([lines count]) [lines removeObjectAtIndex: 0];
            
            if ([lines count]){
                NSString *lastVersion = [lines objectAtIndex: 0];
                // Can be fast, but lets leave it as it is, for the code to be easier to read
                static NSString *lastLabel = @"last: ";
                if ([lastVersion leftSubstringWithLength: [lastLabel length]]) {
                    lastVersion = [lastVersion stringByReplacingOccurrencesOfString:lastLabel withString: @""];
                    NSInteger lastVersionInt = [[lastVersion stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
                    NSInteger currentVersionInt = [[currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""] integerValue];
                    
                    if (currentVersionInt < lastVersionInt) {
                        // We have a new version available
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *lHTML = @"";
                            NSString *currentVersionStr = PODS_NOT_INSTALLED_LABEL;
                            if ([currentVersion length] > 0) {
                                currentVersionStr = [NSString stringWithFormat:@"Current version: %@, ", currentVersion];
                                lHTML = [NSString stringWithFormat:@"%@New version <a href='%@'>%@</a>", currentVersionStr, CHANGELOG_URL_STR, lastVersion];
                            }else {
                                lHTML = PODS_NOT_INSTALLED_LABEL;
                            }
                            
                            NSString *html = [NSString stringWithFormat:@"<div width='100%%' align='right' style=\"font-family:'%@'; font-size:%dpx;\">%@</div>", [font fontName], (int)[font pointSize], lHTML];
                            NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
                            NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
                            [self.lbVersionText setAttributedStringValue: string];
                        });
                    }
                }
            }
        }
    });
}

-(void) refreshRecentProjectsList
{
    NSMutableArray *items = [XCodeProject findAllSortedBy:@"date" ascending: NO].mutableCopy;
    // Lets check if all projects exists
    __block NSMutableArray *itemsToRemove = [NSMutableArray array];
    [items enumerateObjectsUsingBlock:^(XCodeProject *proj, NSUInteger idx, BOOL *stop) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:proj.projectFilePath]) {
            [itemsToRemove addObject: proj];
        }
    }];
    if ([itemsToRemove count]) {
        // Cleanup the missing projects
        [items removeObjectsInArray:itemsToRemove];
        NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
        [itemsToRemove enumerateObjectsUsingBlock:^(XCodeProject *proj, NSUInteger idx, BOOL *stop) {
            [context deleteObject: proj];
        }];
        if ([context hasChanges]) {
            [context saveToPersistentStoreAndWait];
        }
    }
    
    self.xcodeProjects = items;
    [self.recentlyUsedProjects reloadData];
    
    [self.openRecentMenu.submenu removeAllItems];
    for (XCodeProject *proj in self.xcodeProjects) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:proj.name action:@selector(openRecentItem:) keyEquivalent: @""];
        item.tag = [self.xcodeProjects indexOfObject: proj];
        [self.openRecentMenu.submenu addItem: item];
    }
}

-(void) openRecentItem: (NSMenuItem *) sender
{
    XCodeProject *project = [self.xcodeProjects objectAtIndex: sender.tag];
    [self openXCodeProject: project];
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

-(void) openXCodeProject: (XCodeProject *) project
{
    // Lets look for already opened Windows
    __block BOOL alreadyOpened = NO;
    __block CocoaPodWindowController *_controller = nil;
    [self.viewControllers enumerateObjectsUsingBlock:^(CocoaPodWindowController *controller, NSUInteger idx, BOOL *stop) {
        if ([controller.project isSameXCodeProject: project]) {
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

-(void) podManagerUpdateCompleted: (PodSpecManager *)sender
{
    [self.loadingIndicator stopAnimation: self];
    [self.lbStatus setStringValue:@""];
}

-(void) podManager: (PodSpecManager *)sender isUpdatingWithProgress: (CGFloat) progress
{
    [self.lbStatus setStringValue:[NSString stringWithFormat:@"Please wait... %2.2f %%", progress * 100]];
}

-(void) podManager: (PodSpecManager *)sender didFailedWithError: (NSError *) error
{
    [self.loadingIndicator stopAnimation: self];
    [self.lbStatus setStringValue:[NSString stringWithFormat:@"Error: %@", [error description]]];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.xcodeProjects count];
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *result = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
    result.backgroundStyle = NSBackgroundStyleRaised;
    
    XCodeProject *proj = [self.xcodeProjects objectAtIndex: row];
    
    NSTextField *tf = [result viewWithTag: 1];
    if(tf){
        [tf setStringValue: proj.name];
    }
    return result;
}

//-(void)tableViewSelectionDidChange:(NSNotification *)notification{
//    NSInteger cellIndex = [[notification object] selectedRow];
//    if (cellIndex != NSNotFound) {
//        XCodeProject *proj = [self.xcodeProjects objectAtIndex: cellIndex];
//        [self openXCodeProject: proj];
//    }
//}

#pragma mark - Double Click

-(void) tableViewDoubleClick: (id) sender
{
    NSInteger row = [self.recentlyUsedProjects clickedRow];
    if ((row != NSNotFound) && (row > -1)) {
        XCodeProject *proj = [self.xcodeProjects objectAtIndex: row];
        [self openXCodeProject: proj];
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
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(backgroundContextDidSave:)
                               withObject:notification
                            waitUntilDone:YES];
        return;
    }
    // merge in the changes to the main context on the main thread
    [[NSManagedObjectContext defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

@end
