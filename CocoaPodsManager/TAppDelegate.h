//
//  TAppDelegate.h
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet       NSProgressIndicator     *loadingIndicator;
@property (weak) IBOutlet       NSTextField             *lbStatus;
@property (assign) IBOutlet     NSWindow                *window;

@end
