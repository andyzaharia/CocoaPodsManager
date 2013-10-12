//
//  Plugin.m
//  CocoaPodsPlugin
//
//  Created by Andrei Zaharia on 9/16/13.
//  Copyright (c) 2013 Andrei Zaharia. All rights reserved.
//

#import "Plugin.h"
#import "CocoaPodWindowController.h"
#import "CCPWorkspaceManager.h"

#import "XCodeProject+Misc.h"
#import "CocoaProject.h"
#import "CocoaPodsApp.h"

#import "PodRepositoryManager.h"

static Plugin *_sharedPluginInstance = nil;

@interface Plugin ()

@end

@implementation Plugin

+ (void) pluginDidLoad: (NSBundle*) plugin {
	static id sharedPlugin = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
        [NSPersistentStoreCoordinator setDataModelName:@"DataModel"];
        
		sharedPlugin = [[self alloc] init];
	});
}

- (id)init {
	if (self = [super init]) {
        
        _windows = [NSMutableArray array];
        
        _sharedPluginInstance = self;
        
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
	}
	return self;
}

+ (id)sharedPlugin
{
    static dispatch_once_t onceQueue;

    dispatch_once(&onceQueue, ^{ _sharedPluginInstance = [[self alloc] init]; });
    return _sharedPluginInstance;
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification {
    
    [[PodRepositoryManager sharedPodSpecManager] updateAllPodProperties:^{
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:nil];
    
    [self configurePluginMenu];
}

-(void) configurePluginMenu
{
    NSMenuItem* editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (editMenuItem) {
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
        NSString *imagePath = [thisBundle pathForResource:@"PluginIcon26" ofType:@"tiff"];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: imagePath];
        
        NSMenuItem* newMenuItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods Manager"
                                                             action:@selector(showMessageBox:)
                                                      keyEquivalent:@"p"];
        
        [newMenuItem setTarget:self];
        [newMenuItem setImage: image];
        
        [newMenuItem setKeyEquivalentModifierMask: NSAlternateKeyMask];
        [[editMenuItem submenu] addItem:newMenuItem];
    }
}

- (void) selectionDidChange: (NSNotification*) notification {
    if ([[notification object] isKindOfClass:[NSTextView class]]) {
        NSTextView* textView = (NSTextView *)[notification object];
        
        NSArray* selectedRanges = [textView selectedRanges];
        if (selectedRanges.count==0) {
            return;
        }
        
        NSRange selectedRange = [[selectedRanges objectAtIndex:0] rangeValue];
        NSString* text = textView.textStorage.string;
        selectedText = [text substringWithRange:selectedRange];
    }
}

- (void)dealloc
{
    self.windows = nil;
}

- (void) showMessageBox: (id) origin {

    NSString *workspaceDirectoryPath = [CCPWorkspaceManager currentWorkspaceDirectoryPath];
    
    if ([workspaceDirectoryPath length]) {
        
        // Check if this PodFile project isnt already opened.
        NSString *projectPath = [XCodeProject projectPathWithRandomPath: workspaceDirectoryPath];
        __block CocoaPodWindowController *existingWindowController = nil;
        [self.windows enumerateObjectsUsingBlock:^(CocoaPodWindowController *windowController, NSUInteger idx, BOOL *stop) {
            NSString *projPath = windowController.project.xcodeProject.projectFilePath;
            
            if ([projectPath isEqualToString: projPath]) {
                existingWindowController = windowController;
                *stop = YES;
            }
        }];

        if (existingWindowController) {
            
            if (![existingWindowController.window isVisible]) {
                [existingWindowController showWindow: [NSApp mainWindow]];
            }
            
            [existingWindowController.window makeKeyAndOrderFront:self];
        } else {
            
            CocoaPodWindowController *windowController = [[CocoaPodWindowController alloc] initWithWindowNibName:@"CocoaPodWindowController"];
            [windowController openFile: workspaceDirectoryPath];
            [windowController showWindow: [NSApp mainWindow]];
            [windowController.window makeKeyAndOrderFront:self];
            
            [self.windows addObject: windowController];
        }

    } else {
        NSAlert* msgBox = [[NSAlert alloc] init];
        [msgBox setMessageText: @"There is no opened project right now."];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}

#pragma mark - Images Helpers

+(NSImage *) imageWithName: (NSString *) imageName
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [thisBundle pathForResource:imageName ofType:@"png"];
    
    return [[NSImage alloc] initWithContentsOfFile: imagePath];
}

#pragma mark -

@end
