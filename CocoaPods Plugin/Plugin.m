//
//  Plugin.m
//  CocoaPodsPlugin
//
//  Created by Andrei Zaharia on 9/16/13.
//  Copyright (c) 2013 Andrei Zaharia. All rights reserved.
//

#import "Plugin.h"

@implementation Plugin

+ (void) pluginDidLoad: (NSBundle*) plugin {
	static id sharedPlugin = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		sharedPlugin = [[self alloc] init];
	});
}

- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
	}
	return self;
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:nil];
    
    NSMenuItem* editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (editMenuItem) {
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem* newMenuItem = [[NSMenuItem alloc] initWithTitle:@"CocoaPods Manager"
                                                             action:@selector(showMessageBox:)
                                                      keyEquivalent:@"p"];

        [newMenuItem setTarget:self];
        [newMenuItem setKeyEquivalentModifierMask: NSAlternateKeyMask];
        [[editMenuItem submenu] addItem:newMenuItem];
        [newMenuItem release];
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

- (void) showMessageBox: (id) origin {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText: selectedText];
    [alert runModal];
}

@end
