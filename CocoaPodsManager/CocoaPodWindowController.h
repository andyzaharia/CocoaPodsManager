//
//  TMainViewController.h
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CocoaPodWindowController : NSWindowController
{
}

@property (nonatomic, strong)   CocoaProject        *project;
@property (nonatomic)           BOOL                 canClose;

// Returns the list of available pods
- (BOOL)windowShouldClose:(id)sender;

- (IBAction) columnVisibilityToggle: (NSMenuItem *) sender;

- (void) openFile: (NSString *) filePath;

@end
