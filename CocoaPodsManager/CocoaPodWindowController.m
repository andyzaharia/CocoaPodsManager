//
//  TMainViewController.m
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CocoaPodWindowController.h"
#import "CPProject+PodFileParser.h"
#import "CocoaPodsTreeController.h"
#import "PodSpec+StdOutParser.h"
#import "NSApplication+ESSApplicationCategory.h"
#import "NSString+Misc.h"
#import "PodDetailPanel.h"
#import "NSApp+Misc.h"
#import "PodInfoTableCellView.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#import <QuartzCore/QuartzCore.h>

#import "Plugin.h"

#import "CPDependency+Misc.h"

#define LOCAL_POD_PASTEBOARD_TYPE @"LOCAL_POD_PASTEBOARD_TYPE"
#define MAX_RECTENT_PROJECTS 10

static NSString *kCOLUMN_NAME_ID            = @"PodName";
static NSString *kCOLUMN_VERSIONOPERATOR_ID = @"PodVersionOperator";
static NSString *kCOLUMN_VERSION_ID         = @"PodVersion";
static NSString *kCOLUMN_HEAD_ID            = @"PodHead";
static NSString *kCOLUMN_GITSOURCE_ID       = @"PodGitSource";
static NSString *kCOLUMN_LOCALSOURCE_ID     = @"PodLocalSource";
static NSString *kCOLUMN_COMMIT_ID          = @"PodCommit";
static NSString *kCOLUMN_CUSTOMPODSPEC_ID   = @"PodCustomPodSpec";
static NSString *kCOLUMN_TARGET_ID          = @"PodTarget";

static NSString *kCONFIG_KEY = @"CONFIG_KEY";

static NSString *InstalPodToolbarItemIdentifier     = @"Instal Pod Toolbar Item Identifier";
static NSString *UpdatePodToolbarItemIdentifier     = @"Update Pod Toolbar Item Identifier";
static NSString *SavePodToolbarItemIdentifier       = @"Save Pod Toolbar Item Identifier";
static NSString *ActivityToolbarItemIdentifier      = @"Activity Toolbar Item Identifier";

static NSArray *iOS_VERSIONS = nil;
static NSArray *OSX_VERSIONS = nil;

@interface CocoaPodWindowController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    __block  NSMutableArray              *projectPods;
    
    __block     BOOL                     isWorking;
}

@property (assign) IBOutlet             NSOutlineView             *cocoaPodsList;
@property (assign) IBOutlet             NSOutlineView             *projectPodsList;
@property (assign) IBOutlet             NSSearchFieldCell         *searchField;
@property (assign) IBOutlet             NSButton                  *btnInstall;
@property (assign) IBOutlet             NSButton                  *btnUpdate;
@property (assign) IBOutlet             NSButton                  *btnSave;
@property (assign) IBOutlet             NSTextFieldCell           *tfAvailablePods;
@property (assign) IBOutlet             NSPopUpButton             *pbPlatform;
@property (assign) IBOutlet             NSPopUpButton             *pbDeployment;
@property (assign) IBOutlet             NSProgressIndicator       *loadingIndicator;
@property (assign) IBOutlet             NSPanel                   *logSheet;
@property (assign) IBOutlet             NSButton                  *chBxInhibitAllWarnings;
@property (weak) IBOutlet               NSButton                  *btnCloseSheetPanel;
@property (weak) IBOutlet               NSTextField               *tfXCodeProj;
@property (assign) IBOutlet             NSToolbar                 *toolbar;
@property (unsafe_unretained) IBOutlet  NSTextView                *tvLog;

@property (assign) IBOutlet             NSSplitView               *contentSplitViewContainer;

@property (nonatomic, retain)           NSArray                   *pods;
@property (nonatomic, retain)           PodSpec                   *itemBeingDragged;
@property (nonatomic)                   BOOL                      wasEdited;

@property (nonatomic, retain)           PodDetailPanel            *podDetailPanel;

// Test Code

@property (assign) IBOutlet         NSButtonCell                        *testBtn;

@property (weak) IBOutlet           NSSplitView                         *splitView;

@end

@implementation CocoaPodWindowController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName: windowNibName];
    if (self) {
        // Initialization code here.
        if(!iOS_VERSIONS) {
            iOS_VERSIONS = @[@"5.0",@"5.1",@"6.0",@"6.1", @"7.0", @"7.1"];
        }
        
        if(!OSX_VERSIONS) {
            OSX_VERSIONS = @[@"10.6",@"10.7",@"10.8", @"10.9"];
        }
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.canClose = NO;
    self.wasEdited = NO;
    
    if (!self.project) {
        self.project = [CPProject createEntity];
    }else{
        if (self.project.name) {
            self.window.title = self.project.name;
        }
    }
    
    [self.projectPodsList registerForDraggedTypes: @[LOCAL_POD_PASTEBOARD_TYPE, (NSString*)kUTTypeFileURL, NSFilenamesPboardType]];
    
    [self loadPods];
    [self updateUI];
    [self.tfAvailablePods setStringValue:[NSString stringWithFormat:@"Available pods (%ld)", [self.pods count]]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(contextDidSave:)
                                                 name: NSManagedObjectContextDidSaveNotification
                                               object: nil];
    
    [self.projectPodsList setTarget: self];
    [self.projectPodsList setDoubleAction:@selector(doubleClickInTableView:)];
    [self.cocoaPodsList setDoubleAction:@selector(doubleClickInCocoaPodsList:)];
    
    // Register Nibs
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSNib *podInfoCellNib = [[NSNib alloc] initWithNibNamed:@"PodInfoTableCellView" bundle: thisBundle];
    [self.cocoaPodsList registerNib:podInfoCellNib forIdentifier:@"PodInfoTableCellView"];
    
    [self.btnCloseSheetPanel setHidden: ![NSApplication isRunningFromPlugin]];
    
    // Default Column visiblity settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kCONFIG_KEY]) {
        [defaults setBool:YES forKey: kCOLUMN_NAME_ID];  // Yes - visible No - invisible
        [defaults setBool:YES forKey: kCOLUMN_VERSION_ID];
        [defaults setBool:YES forKey: kCOLUMN_HEAD_ID];
        [defaults setBool:YES forKey: kCOLUMN_GITSOURCE_ID];
        [defaults setBool:YES forKey: kCOLUMN_LOCALSOURCE_ID];
        [defaults setBool:NO forKey: kCOLUMN_COMMIT_ID];
        [defaults setBool:NO forKey: kCOLUMN_CUSTOMPODSPEC_ID];
        [defaults setBool:NO forKey: kCOLUMN_TARGET_ID];
        [defaults setBool: YES forKey: kCONFIG_KEY];
        [defaults synchronize];
    }
    
    
    NSArray *columns = [self.projectPodsList tableColumns];
    [columns enumerateObjectsUsingBlock:^(NSTableColumn *column, NSUInteger idx, BOOL *stop) {
        [column setHidden: ![defaults boolForKey: [column identifier]]]; // Note: the column identifier is equal to each column constant id we have declared. Its set from the nib
    }];
    
    [self updateViewMenu];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self.window setFrameAutosaveName:[self.window representedFilename]];
}

-(void) dealloc{
    
    self.projectPodsList.delegate = nil;
    self.projectPodsList.dataSource = nil;
    self.cocoaPodsList.delegate = nil;
    self.cocoaPodsList.dataSource = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    self.project = nil;
}

#pragma mark -

-(void) openFile: (NSString *) filePath{
    
    NSManagedObjectContext *ctx = [NSManagedObjectContext contextForMainThread];
    
    NSString *projectPath = [CPProject projectPathWithRandomPath: filePath];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"projectFilePath LIKE[c] %@", projectPath];
    __block CPProject *prj = [CPProject findFirstWithPredicate: predicate];
        
    [ctx performBlockAndWait:^{
        
        if (!prj) {
            
            NSArray *items = [CPProject findAllSortedBy:@"date" ascending: NO inContext: ctx];
            // We might want to change this...
            if ([items count] >= MAX_RECTENT_PROJECTS) {
                NSInteger itemsToDeleteCount = ([items count] - MAX_RECTENT_PROJECTS);
                NSArray *itemsToDelete = [items subarrayWithRange:NSMakeRange([items count] - itemsToDeleteCount, itemsToDeleteCount)];
                
                for (NSManagedObject *item in itemsToDelete) {
                    [ctx deleteObject: item];
                }
            }
            
            prj = [CPProject createEntityInContext: ctx];
            [prj setPlatformString:@"iOS"]; ////TODO: Possible bug here
            
            [prj setProjectPath: projectPath];
            [prj setName: [[projectPath lastPathComponent] stringByDeletingPathExtension]];
            prj.date = [NSDate date];
            
        } else {
            prj.date = [NSDate date];
            [self.projectPodsList reloadData];
        }
    
        self.project = prj;
        [ctx saveToPersistentStore];
        
        [self updateUI];
    }];
}

-(void) loadPods{
    
    self.cocoaPodsList.delegate = nil;
    self.cocoaPodsList.dataSource = nil;
    
    NSPredicate *predicate = nil;
    NSString *searchTerm = self.searchField.stringValue;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending: YES];
    if ([searchTerm length] > 0) {
        predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) or (desc CONTAINS[cd] %@)", searchTerm, searchTerm];
        self.pods = [[PodSpec findAllWithPredicate: predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    }else{
        self.pods = [[PodSpec findAll] sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    
    self.cocoaPodsList.delegate = self;
    self.cocoaPodsList.dataSource = self;
    
    [self.cocoaPodsList reloadData];
}

#pragma mark - IBActions

- (IBAction)searchTermDidChange:(id)sender {
    [self loadPods];
}

- (IBAction)updateAction:(id)sender {
    
    [self.loadingIndicator setHidden: NO];
    [self.loadingIndicator startAnimation: self];
    
    isWorking = YES;
    
    [self.toolbar validateVisibleItems];
    
    [self.project writeProjectToPodFile];
    
    __weak CocoaPodWindowController *weakSelf = self;
    [CocoaPodsApp updateProject:self.project withOptions:@[] onSuccess:^(NSString *response) {
        
        isWorking = NO;
        
        [weakSelf.loadingIndicator stopAnimation: self];
        [weakSelf.loadingIndicator setHidden: YES];
        [weakSelf.toolbar validateVisibleItems];
         weakSelf.wasEdited = NO;
        
        ESSBeginAlertSheet(@"Done !",
                           @"OK",
                           @"View Logs",
                           NULL,
                           self.window,
                           NULL,
                           ^(void *contextInf, NSInteger returnCode) {
                               if(returnCode == NSAlertAlternateReturn) {
                                   [self showLogWindowWithString: response];
                               }
                           },
                           NULL,
                           @" ");
        
    }onError:^(NSError *error) {
        
        isWorking = NO;
        [weakSelf.loadingIndicator stopAnimation: self];
        [weakSelf.loadingIndicator setHidden: YES];
        [weakSelf.toolbar validateVisibleItems];
        
        ESSBeginAlertSheet(
                           @"Failed !",
                           @"OK",
                           @"View Logs",
                           NULL,
                           self.window,
                           NULL,
                           ^(void *contextInf, NSInteger returnCode) {
                               if(returnCode == NSAlertAlternateReturn) {
                                   NSString *info  = error.userInfo[NSLocalizedDescriptionKey];
                                   [self showLogWindowWithString: info];
                               }
                           },
                           NULL,
                           @" ");
        
    }];
}


- (IBAction)installAction:(id)sender {
    
    if (!self.project) {
        NSBeginAlertSheet(@"Warning",
                          @"Yes",
                          @"No",
                          NULL,
                          self.window,
                          self,
                          NULL,
                          @selector(openDialogForXCodeProject:returnCode:contextInfo:),
                          NULL,
                          @"No destination project has been specified. Do you want to select a project ?",
                          NULL
                          );
        return;
    }
    
    self.wasEdited = NO;
    
    [self.loadingIndicator setHidden: NO];
    [self.loadingIndicator startAnimation: self];
    isWorking = YES;
    
    __weak CocoaPodWindowController *weakSelf = self;
    
    PodExecOnSucceedBlock onSuccess = ^(NSString *error) {
        
        isWorking = NO;
        [weakSelf.loadingIndicator stopAnimation: weakSelf];
        [weakSelf.loadingIndicator setHidden: YES];
        [weakSelf.toolbar validateVisibleItems];
        weakSelf.wasEdited = NO;
        
        NSString *doneMessage = [NSString stringWithFormat:@"From now on use '%@.xcworkspace'", weakSelf.project.name];
        NSBeginAlertSheet(
                          @"Done !",
                          @"OK",
                          @"Open",
                          NULL,
                          weakSelf.window,
                          weakSelf,
                          NULL,
                          @selector(installDoneModalDidDismissed:returnCode:contextInfo:),
                          NULL,
                          doneMessage,
                          NULL
                          );
    };
    
    PodExecOnProgressBlock onProgress = ^(NSString *outputString) {        
        NSLog(@"Progress: %@", outputString);

    };
    
    PodExecOnFailBlock onError = ^(NSError *error) {
        
        isWorking = NO;
        [weakSelf.loadingIndicator stopAnimation: self];
        [weakSelf.loadingIndicator setHidden: YES];
        [weakSelf.toolbar validateVisibleItems];
        
        ESSBeginAlertSheet(
                           @"Failed !",
                           @"OK",
                           @"View Logs",
                           NULL,
                           self.window,
                           NULL,
                           ^(void *contextInf, NSInteger returnCode) {
                               if(returnCode == NSAlertAlternateReturn) {
                                   [self showLogWindowWithString: [error domain]];
                               }
                           },
                           NULL,
                           @" ");
    };
    
    
    [CocoaPodsApp installCocoaPodsInProject: self.project
                                  onSuccess: onSuccess
                                 onProgress: onProgress
                                withOnError: onError];
}


- (IBAction)saveAction:(id)sender {
    if (!self.project) {
        NSBeginAlertSheet(@"Warning",
                          @"Yes",
                          @"No",
                          NULL,
                          self.window,
                          self,
                          NULL,
                          @selector(openDialogForXCodeProject:returnCode:contextInfo:),
                          NULL,
                          @"No destination project has been specified. Do you want to select a project ?",
                          NULL
                          );
        return;
    }
    
    [self.project writeProjectToPodFile];
    self.wasEdited = NO;
}

-(IBAction)inhibitAllWarningsAction:(NSButton *)sender {
    self.project.inhibit_all_warnings = @([sender state]);
}

- (IBAction)podVersionChanged:(NSPopUpButton *)sender {
    
    self.wasEdited = YES;
    
    NSInteger row = [self.projectPodsList rowForView: sender];
    CPDependency *dependencyItem = [self.projectPodsList itemAtRow:row];
    dependencyItem.versionStr = [sender selectedItem].title;
}

- (IBAction)refresh:(id)sender {
    
    [self.projectPodsList reloadData];
}

- (IBAction)deletePodFromProject:(NSButton *)sender {
    
    NSInteger row = [self.projectPodsList rowForView:sender];
    [self _removeItemAtRow: row];
    
    self.wasEdited = YES;
}

- (IBAction)platformDidChange:(NSPopUpButton *)sender {
    
    NSMenuItem *item = [sender selectedItem];
    self.project.platformString = [item.title lowercaseString];
    
    self.wasEdited = YES;
    
    [self configureDeploymentVersionsWithPlatformString: self.project.platformString];
}

- (IBAction)deploymentDidChange:(NSPopUpButton *)sender {
    
    NSMenuItem *item = [sender selectedItem];
    if ([item.title length] > 1) {
        self.project.deploymentString = item.title;
    }else{
        self.project.deploymentString = @"";
    }
    
    self.wasEdited = YES;
}

-(void) configureDeploymentVersionsWithPlatformString: (NSString *) platform
{
    [self.pbDeployment removeAllItems];
    
    BOOL isiOSPlatform = [[platform lowercaseString] isEqualToString:@"ios"]; // Darn make this an enum type ...
    NSMutableArray *items = [NSMutableArray arrayWithArray: (isiOSPlatform) ? iOS_VERSIONS : OSX_VERSIONS];
    [items insertObject:@"-" atIndex: 0];
    
    for (NSString *item in items) {
        [self.pbDeployment addItemWithTitle: item];
    }
}

- (IBAction)headValueChanged:(NSButton *)sender {
    
    NSInteger row = [self.projectPodsList rowForView: sender];
    CPDependency *dependencyItem = [self.projectPodsList itemAtRow:row];
    dependencyItem.head = @(sender.state);
    
    self.wasEdited = YES;
}

-(IBAction) columnVisibilityToggle: (NSMenuItem *) sender{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *columnID = @"";
    switch (sender.tag) {
        case 0:
            columnID = kCOLUMN_VERSIONOPERATOR_ID;
            break;
        case 1:
            columnID = kCOLUMN_HEAD_ID;
            break;
        case 2:
            columnID = kCOLUMN_GITSOURCE_ID;
            break;
        case 3:
            columnID = kCOLUMN_LOCALSOURCE_ID;
            break;
        case 4:
            columnID = kCOLUMN_COMMIT_ID;
            break;
        case 5:
            columnID = kCOLUMN_CUSTOMPODSPEC_ID;
            break;
        case 6:
            columnID = kCOLUMN_TARGET_ID;
            break;
            
        default:
            break;
    }
    
    NSInteger columnIndex = [self.projectPodsList columnWithIdentifier: columnID];
    NSTableColumn *column = [[self.projectPodsList tableColumns] objectAtIndex: columnIndex];
    
    BOOL state = ![defaults boolForKey: columnID];
    [column setHidden: !state];
    [sender setState: state];
    [defaults setBool: state forKey: columnID];
    
    [defaults synchronize];
}

- (IBAction)podOpenHomePageAction:(id)sender {
    
    NSInteger row = [self.cocoaPodsList rowForView:sender];
    PodSpec *pod = self.pods[row];
    if ([pod.homePage length]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: pod.homePage]];
    } else {
    
        TODO("Clean this mess.")
        
        NSArray *yamlContent = [pod lastVersionYAML];
        NSDictionary *yamlDictionary = [yamlContent lastObject];
        if (yamlDictionary) {
            NSString *homePage = [yamlDictionary objectForKey:@"homepage"];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: homePage]];
        } else {
            // YAML not retrieved, maybe throw an error ?
             TODO("Show a ... home page not provided alert/dialog.")
        }
    }
}

- (IBAction)addPodDependencyWithCheckoxStateChange:(NSButton *)sender {
    NSInteger row = [self.cocoaPodsList rowForView:sender];
    PodSpec *pod = self.pods[row];
    
    if(sender.state == 0) {
        // Remove Pod
        CPDependency *dependency = [self.project dependencyForPod: pod];
        if (dependency) {
            NSInteger index = [self.project.items indexOfObject: dependency];
            if(index != NSNotFound) {
                [self _removeItemAtRow: index];
            }
        }
    } else {
        // Add pod
        CPDependency *dependency = [CPDependency dependencyWithPod: pod];
        [dependency setProject: self.project];
        
        [self.projectPodsList insertItemsAtIndexes: [NSIndexSet indexSetWithIndex: [self.project.items indexOfObject: dependency]]
                                          inParent: nil
                                     withAnimation: NSTableViewAnimationEffectGap];
    }
    
    self.wasEdited = YES;
}

- (IBAction)pickXcodeProject:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setPrompt:@"Choose"];
    [panel setTitle:@"Choose Project"];
    
    NSString *defaultDirectoryPath = [self.project.projectFilePath stringByDeletingLastPathComponent];
    [panel setDirectoryURL:[NSURL URLWithString: defaultDirectoryPath]];
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            // do something with the url here.
            NSString *path = [url path]; NSLog(@"Path: %@", path);
            [self.tfXCodeProj setStringValue: path];
        }
    }
}

- (IBAction)closeSheetPanel:(id)sender {
    [NSApp endSheet: self.window returnCode: 0];
    [self.window orderOut: self];
}

#pragma mark Custom Methods

-(void) doubleClickInCocoaPodsList: (id) sender{
    
    NSInteger row = [self.cocoaPodsList clickedRow];
    //NSInteger column = [self.cocoaPodsList clickedColumn];
    
    PodSpec *pod = nil;
    if(row > -1) {
        pod = [self.pods objectAtIndex: row];
    }
    
    if (!self.podDetailPanel) {
        NSNib *panelNib = [[NSNib alloc] initWithNibNamed:@"PodDetailPanel" bundle: nil];
        NSArray *topLevelObjects;
        if ([panelNib instantiateWithOwner:self topLevelObjects: &topLevelObjects]) {
            for (id topLevelObject in topLevelObjects) {
                if ([topLevelObject isKindOfClass:[PodDetailPanel class]]) {
                    self.podDetailPanel = topLevelObject;
                    break;
                }
            }
        }
        
        if (self.podDetailPanel) {
            __weak CocoaPodWindowController *weakSelf = self;
            [self.podDetailPanel setOnDone: ^{
                [NSApp endSheet: weakSelf.podDetailPanel];
            }];
        }
    }
    
    
    if (pod) {
        [self.podDetailPanel displayPodSpec: pod];
        
        
//        [NSApp beginSheet: self.podDetailPanel
//           modalForWindow: [self window]
//            modalDelegate: self
//           didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//              contextInfo: nil];
        
    }
}

- (void)doubleClickInTableView:(id)sender{
    
    NSInteger row = [self.projectPodsList clickedRow];
    NSInteger column = [self.projectPodsList clickedColumn];
    
    if(row >= 0 && column >= 0){
        NSTableColumn *tableColumn = [[self.projectPodsList tableColumns] objectAtIndex:column];
        NSView *rowView = [self outlineView: self.projectPodsList
                         viewForTableColumn: tableColumn
                                       item: [self.project.items objectAtIndex: row]];
        NSTextField *textField = [rowView viewWithTag: 1];
        if (textField) {
            [self.projectPodsList editColumn:column row:row withEvent:nil select:YES];
        }
    }
}

- (BOOL)windowShouldClose:(id)sender{
    
    if(self.wasEdited){
        NSAlert* msgBox = [NSAlert alertWithMessageText:@"Hey, wait a second."
                                          defaultButton:@"Yes"
                                        alternateButton:@"Cancel"
                                            otherButton:@"No"
                              informativeTextWithFormat: @"Do you want to save the modified pod file ?"];
        [msgBox beginSheetModalForWindow: self.window
                           modalDelegate: self
                          didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:)
                             contextInfo: nil];
        
        return NO;
    }else{
        self.canClose = YES;
    }
    
    return self.canClose;
}

- (void) alertDidEnd:(NSAlert *) alert returnCode:(int) returnCode contextInfo:(int *) contextInfo
{
    if(returnCode == NSAlertDefaultReturn){
        // Save the pod file
        [self.project writeProjectToPodFile];
    }
    
    self.canClose = YES;
    
    if (returnCode != NSAlertAlternateReturn) {
        [self close];
    }    
}

#pragma mark - Notifications

- (void)contextDidSave:(NSNotification *)notification {
    // Make sure we're on the main thread when updating the main context
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(contextDidSave:)
                               withObject:notification
                            waitUntilDone:YES];
        return;
    }
    
    [self loadPods];
    [self.tfAvailablePods setStringValue:[NSString stringWithFormat:@"Available pods (%ld)", [[PodSpec findAll] count]]];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return YES;
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem{
    return YES;
}

-(void) updateViewMenu{
    
    NSMenuItem *viewMenuItem = [[[NSApplication sharedApplication] mainMenu] itemWithTag:3];
    [viewMenuItem setHidden: NO];
    [viewMenuItem setEnabled: YES];
    
    NSMenu *viewMenu = [viewMenuItem submenu];
    
    // This switch thing should be optimized as... its kind of a ... cr**
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [[viewMenu itemArray] enumerateObjectsUsingBlock:^(NSMenuItem *menuItem, NSUInteger idx, BOOL *stop) {
        [menuItem setEnabled: YES];
        
        NSString *columnID = @"";
        switch (menuItem.tag) {
            case 0:
                columnID = kCOLUMN_VERSIONOPERATOR_ID;
                break;
            case 1:
                columnID = kCOLUMN_HEAD_ID;
                break;
            case 2:
                columnID = kCOLUMN_GITSOURCE_ID;
                break;
            case 3:
                columnID = kCOLUMN_LOCALSOURCE_ID;
                break;
            case 4:
                columnID = kCOLUMN_COMMIT_ID;
                break;
            case 5:
                columnID = kCOLUMN_CUSTOMPODSPEC_ID;
                break;
            case 6:
                columnID = kCOLUMN_TARGET_ID;
                break;
            default:
                break;
        }
        
        BOOL state = [defaults boolForKey: columnID];
        [menuItem setState: state];
    }];
}

- (void)updateUI {
    
    if ([self.project.platformString length] > 0) {
        NSArray *items = [self.pbPlatform itemArray];
        for (NSMenuItem *item in items) {
            if ([[item.title lowercaseString] isEqualToString: [self.project.platformString lowercaseString]]) {
                [self.pbPlatform selectItem: item];
            }
        }
        
        [self configureDeploymentVersionsWithPlatformString: self.project.platformString];
    }
    
    if ([self.project.deploymentString length] > 0){
        
        NSString *_deployment = self.project.deploymentString;
        NSArray *items = [self.pbDeployment itemArray];
        for (NSMenuItem *item in items) {
            NSString *itemLowerCaseTitle = [[item.title lowercaseString] leftSubstringWithLength: [_deployment length]];
            if ([itemLowerCaseTitle isEqualToString: _deployment]) {
                [self.pbDeployment selectItem: item];
            }
        }
    }else{
        [self.pbDeployment selectItemAtIndex:0];
    }
    
//    [self.btnInstall setEnabled: ![self.project isPodInstalledForProject]];
//    [self.btnUpdate setEnabled: [self.project isPodInstalledForProject]];
    
    [self.btnInstall setEnabled: YES];
    [self.btnUpdate setEnabled: YES];
    
    self.chBxInhibitAllWarnings.state = [self.project.inhibit_all_warnings boolValue];

}

#pragma mark - Sheet delegates

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    
    [sheet orderOut:self];
}

#pragma mark -

-(void) installDoneModalDidDismissed: (id) sender returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo{
    
    if(returnCode == NSAlertAlternateReturn){
        [[NSWorkspace sharedWorkspace] openFile: [self.project workSpaceFilePath]
                                withApplication: @"XCode"];
    }
}

-(void) openDialogForXCodeProject: (id) sender returnCode: (NSInteger)returnCode contextInfo: (void *)contextInfo{
    
    if(returnCode == NSAlertDefaultReturn){
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        [openDlg setCanChooseFiles:YES];
        [openDlg setCanChooseDirectories:YES];
        if ([openDlg runModal] == NSOKButton ){
            NSURL *file = [openDlg URL];
            [self openFile: [file path]];
        }
    }
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //NSLog(@"Data: %@", self.cocoaPodsDataController.arrangedObjects);
}


#pragma mark - NSTableView

// Configures the view for the available pods
-(NSView *) viewForCocoaPodsListTableView: (NSView *) view forTableColumn:(NSTableColumn *)tableColumn item:(id)item{

    if ([view isKindOfClass:[NSTableCellView class]]) {
        PodInfoTableCellView *cellView = (PodInfoTableCellView *)view;
        if ([item isKindOfClass:[PodSpec class]]) {
            PodSpec *pod = (PodSpec *)item;
            
            if ([cellView isKindOfClass:[PodInfoTableCellView class]]) {
                [cellView displayPodSpec: pod isInstalled: [self.project containsPod: pod]];
            }
            
            [cellView.btnInstalled setTarget: self];
            [cellView.btnInstalled setAction: @selector(addPodDependencyWithCheckoxStateChange:)];
            
        }else{
            if([item isKindOfClass:[NSString class]]){
                if ([item length] == 0) {
                    item = @"";
                }
                [cellView.textField setStringValue: item];
                [cellView.textField setFont:[NSFont systemFontOfSize:10]];
            }else{
                [cellView.textField setStringValue: @""];
            }
        }
    }
    
    return view;
}

-(NSView *) viewForXCodePodsListTableView: (NSView *) view forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    
    CPDependency *dependency = nil;
    if ([item isKindOfClass:[CPDependency class]]) {
        dependency = (CPDependency *)item;
    }
    
    if ([[tableColumn identifier] isEqualToString:kCOLUMN_VERSION_ID]) {
        
        if ([item isKindOfClass:[CPDependency class]] && [view isKindOfClass:[NSView class]]) {
            
            NSPopUpButton *popupButton = (NSPopUpButton *)view;
            [popupButton removeAllItems];
            
            PodSpec *pod = [dependency pod];
            NSMutableArray *items = [pod versionsArray];
            [items insertObject:@"" atIndex: 0];
            [items insertObject:@"Head" atIndex: 1];
            for (NSString *item in items) {
                [popupButton addItemWithTitle: item];
            }
            
            //Lets select the MenuItem
            if ([dependency.versionStr length] > 0) {
                NSInteger index = [items indexOfObject: dependency.versionStr];
                if (index != NSNotFound) {
                    NSMenuItem *item = [popupButton itemWithTitle:dependency.versionStr];
                    [popupButton selectItem: item];
                }
            }
        }
    }else if ([[tableColumn identifier] isEqualToString:kCOLUMN_VERSIONOPERATOR_ID]) {
        NSPopUpButton *popupButton = (NSPopUpButton *)view;
        if ([dependency.versionStr length] > 0) {
            if ([dependency.versionStr isEqualToString:@"Head"]) {
                [popupButton setEnabled: NO];
            }else {
                [popupButton.itemArray enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
                    if ([dependency.versionOperator isEqualToString: item.title]) {
                        [popupButton selectItem: item];
                    }
                }];
            }
        }
    }else if ([[tableColumn identifier] isEqualToString:kCOLUMN_GITSOURCE_ID]) {
        NSTextField *textField = [view viewWithTag: 1];
        if (textField && dependency) {
            if ([dependency.gitSource length]) {
                [textField setStringValue: dependency.gitSource];
            }else{
                [textField setStringValue: @""];
            }
        }
    }else if ([view isKindOfClass:[NSTableCellView class]]){
        NSTableCellView *cellView = (NSTableCellView *)view;
        if ([item isKindOfClass:[CPDependency class]]) {
            PodSpec *pod = [(CPDependency *)item pod];
            if (pod) {
                [cellView.textField setStringValue: [pod.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }else {
                [cellView.textField setStringValue: @"Error"];
            }
            
            // XCode 5 IB bug, for some unkown reason it keeps changing the frame in the nib
            [cellView.textField sizeToFit];
            
            NSRect textFieldRect = NSMakeRect(32.0,
                                              cellView.bounds.size.height * 0.5 - cellView.textField.frame.size.height * 0.5,
                                              cellView.bounds.size.width - 32.0,
                                              cellView.textField.frame.size.height);
            [cellView.textField setFrame: textFieldRect];
            
            NSView *btnView = [cellView viewWithTag: 2];
            [btnView setFrame: NSMakeRect(1.0,
                                          cellView.bounds.size.height * 0.5 - btnView.frame.size.height * 0.5,
                                          btnView.frame.size.width,
                                          btnView.frame.size.height)];
        }
    }else if ([[tableColumn identifier] isEqualToString:kCOLUMN_HEAD_ID]) {
        NSButton *button = [view viewWithTag: 1];
        
        if(dependency && button) {
            button.state = [dependency.head boolValue];
        }
    }
    else if ([[tableColumn identifier] isEqualToString:kCOLUMN_TARGET_ID]) {
        NSComboBox *button = [view viewWithTag: 1];
        
        if(dependency && button) {
            //NSLog(@"Combo");
        }
    }
    
    
    return view;
}

#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    if (self.cocoaPodsList == outlineView) {
        return item ? 4 : [self.pods count];
    } else if (self.projectPodsList == outlineView) {
        if (!item) {
            return [self.project.items count];
        }
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (self.cocoaPodsList == outlineView) {
        if (item) {
            PodSpec *pod = (PodSpec *)item;
            
            // Paranoic...
            if (![pod isKindOfClass:[PodSpec class]]) return @"";
            
            NSString *strDescription = @"";
            switch (index) {
                case 0:
                    strDescription = [pod childDescription];
                    break;
                case 1:
                    strDescription = [pod childHomePage];
                    break;
                case 2:
                    strDescription = [pod childSourcePage];
                    break;
                case 3:
                    strDescription = [pod childVersions];
                    break;
                default:
                    break;
            }
            return strDescription;
        }else{
            return [self.pods objectAtIndex: index];
        }
        
    }else if (self.projectPodsList == outlineView) {
        
        if (item) {
            return nil;
        } else {
            if (index < [self.project.items count]) {
                return [self.project.items objectAtIndex: index];
            }
        }
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    
    if (outlineView == self.projectPodsList) {
        return NO;
    }
    
    return ![item isKindOfClass:[PodSpec class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
    if (outlineView == self.cocoaPodsList) {
        NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
        return [self viewForCocoaPodsListTableView:result forTableColumn:tableColumn item: item];
    }
    
    if (outlineView == self.projectPodsList) {
        NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
        return [self viewForXCodePodsListTableView:result forTableColumn:tableColumn item: item];
    }
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems{
    
    self.itemBeingDragged = nil;
    
    if (self.projectPodsList == outlineView) {
        [session.draggingPasteboard clearContents];
        return;
    }
    
    self.itemBeingDragged = [draggedItems lastObject];
    [session.draggingPasteboard setData:[NSData data] forType:LOCAL_POD_PASTEBOARD_TYPE];
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    // If the session ended in the trash, then delete all the items
    self.itemBeingDragged = nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    return NSDragOperationCopy;
}

// Multiple item dragging support. Implementation of this method is required to change the drag images into what we want them to look like when over our view
- (void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo {
    if ([draggingInfo draggingSource] != self.projectPodsList) {
        __block NSInteger validCount = 0;
        draggingInfo.numberOfValidItemsForDrop = validCount;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(PodSpec *)item childIndex:(NSInteger)childIndex {
    
    if ([item isKindOfClass:[CPDependency class]]) return NO;
    
    
    __block BOOL drop = NO;
    NSArray *classes = [NSArray arrayWithObject:[PodSpec class]];
    [info enumerateDraggingItemsWithOptions:0 forView:outlineView classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
        PodSpec *newNodeData = (PodSpec *)draggingItem.item;
        if ([self.project containsPod: newNodeData]) {
            drop = YES;
            *stop = YES;
        }
    }];
    
    if (drop) return NO;
    
    
    // Else go agead...
    
    if (outlineView == self.projectPodsList) {
        [self.projectPodsList beginUpdates];
        // If the source was ourselves, we use our dragged nodes and do a reorder
        
        [self _performInsertWithDragInfo:info parentNode:nil childIndex:childIndex];
        [self.projectPodsList endUpdates];
    }
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    if ([files count] > 0) {
        NSString *filePath = [files lastObject];
        [self openFile:filePath];
    }
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard{
    
    return (self.projectPodsList != outlineView);
}

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    
    return ([item isKindOfClass:[CPDependency class]]) ? nil: (id <NSPasteboardWriting>)item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (self.cocoaPodsList == outlineView) {
        if ([item isKindOfClass:[PodSpec class]]) {
            PodSpec *pod = (PodSpec *)item;
            // Check if the Pod has the description fetched
            if (![pod.fetchedDetails boolValue]) {
                // This will slow down the app a lot.
                
                __weak CocoaPodWindowController *weakSelf = self;
                NSInteger row = [weakSelf.cocoaPodsList rowForItem: item];
                
                OnDoneEx onDone = ^(NSDictionary *properties) {
                    [pod applyProperties: properties];
                    [weakSelf.cocoaPodsList reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex:row]
                                                      columnIndexes: [NSIndexSet indexSetWithIndex:0]];
                };

                [pod fetchPropertiesAsyncWithVersion:[pod lastVersion] onDone:onDone onFailure: nil];
            }
        }

    }
    
    return YES;
}

#pragma mark - Expand And Load Data

// Not using this for now...
-(void) setLoadingIndicatiorState: (BOOL) animated forItem: (id) item withOutlineView: (NSOutlineView *) outlineView{
    
    NSView *rowView = [self outlineView: outlineView
                     viewForTableColumn: [outlineView tableColumnWithIdentifier: @"PodAction"]
                                   item: item];
    if (!rowView)  return;
    
    NSArray *subViews = [rowView subviews];
    [subViews enumerateObjectsUsingBlock:^(NSProgressIndicator *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSProgressIndicator class]]) {
            animated ? [obj startAnimation: self] : [obj stopAnimation: self];
            *stop = YES;
        }
    }];
}

-(void) outlineViewItemDidExpand: (NSNotification *) notification{
    
    if([notification object] != self.cocoaPodsList) return;
    
    __block PodSpec *podSpec = (PodSpec *)[[notification userInfo] objectForKey:@"NSObject"];
    
    if(![podSpec isKindOfClass:[PodSpec class]] || [podSpec.fetchedDetails boolValue]) return;
    
    podSpec.childLoading = @YES;
    
    NSManagedObjectID *objectID = [podSpec objectID];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
        [context performBlockAndWait:^{
            
            PodSpec *_podSpec = (PodSpec *)[context objectWithID: objectID];
            if(_podSpec){
                
                NSArray *versions = [_podSpec versionsArray];
                if ([versions count]) {
                    versions = [versions sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                    NSString *lastVersion = [versions lastObject];
                    [_podSpec fetchYamlPropertiesWithVersion: lastVersion];
                }
            }
        }];
        
        if ([context hasChanges]) {
            [context saveToPersistentStore];
        }
    });    
}

#pragma mark -

- (void)_performInsertWithDragInfo:(id <NSDraggingInfo>)info parentNode:(NSTreeNode *)parentNode childIndex:(NSInteger)childIndex {
    
    // NSOutlineView's root is nil
    id outlineParentItem = nil;
    //NSMutableArray *childNodeArray = [parentNode mutableChildNodes];
    NSInteger outlineColumnIndex = [[self.projectPodsList tableColumns] indexOfObject:[self.projectPodsList outlineTableColumn]];
        
    __weak CocoaPodWindowController *weakSelf = self;
    
    // Enumerate all items dropped on us and create new model objects for them
    NSArray *classes = [NSArray arrayWithObject:[PodSpec class]];
    __block NSInteger insertionIndex = childIndex >= 0 ? childIndex : 0;
    [info enumerateDraggingItemsWithOptions:0 forView:self.projectPodsList classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
            
        PodSpec *newNodeData = (PodSpec *)draggingItem.item;
        // Wrap the model object in a tree node
        NSTreeNode *treeNode = [NSTreeNode treeNodeWithRepresentedObject:newNodeData];
        // Add it to the model
        
        weakSelf.wasEdited = YES;
        
        CPDependency *dependency = [CPDependency dependencyWithPod: newNodeData];
        
        if (insertionIndex < 0) {
            dependency.project = self.project;
        }else{
            [weakSelf.project insertItems:@[dependency] atIndexes:[NSIndexSet indexSetWithIndex: insertionIndex]];
        }
        
        [weakSelf.projectPodsList insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex]
                                              inParent:outlineParentItem
                                         withAnimation:NSTableViewAnimationEffectGap];
        // Update the final frame of the dragging item
        NSInteger row = [weakSelf.projectPodsList rowForItem:treeNode];
        draggingItem.draggingFrame = [weakSelf.projectPodsList frameOfCellAtColumn:outlineColumnIndex row:row];
        
        // Insert all children one after another
        insertionIndex++;
    }];
}

- (void)_removeItemAtRow:(NSInteger)row {
    
    NSManagedObjectContext *ctx = [NSManagedObjectContext contextForMainThread];
    [ctx performBlock:^{
        CPDependency *item = [self.projectPodsList itemAtRow:row];
        item.project = nil;
        
        [self.projectPodsList removeItemsAtIndexes: [NSIndexSet indexSetWithIndex: row]
                                          inParent: nil
                                     withAnimation: NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft];
        
        [self.cocoaPodsList reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex: [self.pods indexOfObject: item.pod]]
                                      columnIndexes:[NSIndexSet indexSetWithIndex: 0]];
        
        [ctx deleteObject: item];

    }];
}

#pragma mark - Misc


-(void) textFieldValueChanged: (NSTextView *) textField{
    
    NSInteger rowIndex = [self.projectPodsList rowForView: textField];
    NSInteger columnIndex = [self.projectPodsList columnForView: textField];
    
    NSTableColumn *tableColumn = [[self.projectPodsList tableColumns] objectAtIndex: columnIndex];
    if (tableColumn) {
        CPDependency *dependencyItem = [self.projectPodsList itemAtRow:rowIndex];
        
        if ([[tableColumn identifier] isEqualToString: kCOLUMN_GITSOURCE_ID]) {
            dependencyItem.gitSource = [textField string];
        }else if ([[tableColumn identifier] isEqualToString: kCOLUMN_LOCALSOURCE_ID]) {
            dependencyItem.local = [textField string];
        }else if ([[tableColumn identifier] isEqualToString: kCOLUMN_COMMIT_ID]){
            dependencyItem.commit = [textField string];
        }else if ([[tableColumn identifier] isEqualToString: kCOLUMN_CUSTOMPODSPEC_ID]){
            dependencyItem.customPodSpec = [textField string];
        }
    }
    
    self.wasEdited = YES;
}

#pragma mark - Setters

-(void) setWasEdited:(BOOL)edited{
    
    _wasEdited = edited;
    
    [self.btnSave setEnabled: edited];
    
//    [self.btnInstall setEnabled: ![self.project isPodInstalledForProject]];
//    [self.btnUpdate setEnabled: [self.project isPodInstalledForProject]];
    
    [self.btnInstall setEnabled: YES];
    [self.btnUpdate setEnabled: YES];
}

#pragma mark -

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    
    return YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
    
    NSDictionary *userInfo = [aNotification userInfo];
    NSTextView *textField = [userInfo objectForKey:@"NSFieldEditor"];
    [self textFieldValueChanged: textField];
}

#pragma mark - Log Panel

- (IBAction)showLogWindowWithString:(NSString *)logStr {
    
    [self.tvLog setString: logStr];
    [NSApp beginSheet: self.logSheet
       modalForWindow: self.window
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (IBAction)closeLogPanel:(id)sender {
    
    [NSApp endSheet:self.logSheet];
    [self.logSheet orderOut:sender];
}

#pragma mark - NSToolBar Delegate

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
    if ([itemIdent isEqualToString: UpdatePodToolbarItemIdentifier]) {
        [toolbarItem setLabel: @"Update"];
        [toolbarItem setPaletteLabel: @"Update"];
        
        [toolbarItem setToolTip: @"Update Pod"];
        [toolbarItem setImage: [Plugin imageWithName: @"update"]];
        // Tell the item what message to send when it is clicked
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(updateAction:)];
    }else if ([itemIdent isEqualToString: InstalPodToolbarItemIdentifier]) {
        [toolbarItem setLabel: @"Install"];
        [toolbarItem setPaletteLabel: @"Install"];
        
        [toolbarItem setToolTip: @"Install Pod"];
        
        
        [toolbarItem setImage: [Plugin imageWithName: @"install"]];
        // Tell the item what message to send when it is clicked
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(installAction:)];
    }else if ([itemIdent isEqualToString: SavePodToolbarItemIdentifier]) {
        [toolbarItem setLabel: @"Save"];
        [toolbarItem setPaletteLabel: @"Save"];
        
        [toolbarItem setToolTip: @"Save Pod File"];
        [toolbarItem setImage: [Plugin imageWithName: @"save_as"]];
        // Tell the item what message to send when it is clicked
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(saveAction:)];
    }else if ([itemIdent isEqualToString: ActivityToolbarItemIdentifier]) {
        
        NSProgressIndicator *indicator = [[NSProgressIndicator alloc] initWithFrame: NSMakeRect(0, 0, 16, 16)];
        [indicator setStyle: NSProgressIndicatorSpinningStyle];
        [indicator setDisplayedWhenStopped: NO];
        [indicator setCanDrawConcurrently: YES];
        
        self.loadingIndicator = indicator;
        
        [toolbarItem setLabel: @""];
        [toolbarItem setPaletteLabel: @""];
        [toolbarItem setView: indicator];
    }
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used
    return @[InstalPodToolbarItemIdentifier,
             UpdatePodToolbarItemIdentifier,
             SavePodToolbarItemIdentifier,
             NSToolbarFlexibleSpaceItemIdentifier,
             ActivityToolbarItemIdentifier];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed
    // The set of allowed items is used to construct the customization palette
    return @[InstalPodToolbarItemIdentifier,
             UpdatePodToolbarItemIdentifier,
             SavePodToolbarItemIdentifier,
             NSToolbarFlexibleSpaceItemIdentifier,
             ActivityToolbarItemIdentifier];
}

#pragma mark - NSToolbarItemValidation

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    BOOL enable = NO;
    if (isWorking) {
        return NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqual: InstalPodToolbarItemIdentifier]) {
//        enable = ![self.project isPodInstalledForProject];
        enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: UpdatePodToolbarItemIdentifier]) {
//        enable = [self.project isPodInstalledForProject];
          enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: SavePodToolbarItemIdentifier]) {
        enable = YES;
    }
    return enable;
}

#pragma mark - NSSplitViewDelegate

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    if([userInfo[@"name"] isEqualToString: NSSplitViewDidResizeSubviewsNotification]) {
        NSView *view = userInfo[@"object"];
        [view setNeedsDisplay: YES];
    }
}

@end
