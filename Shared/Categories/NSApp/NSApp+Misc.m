//
//  NSApp+Misc.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/22/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSApp+Misc.h"

@implementation NSApplication (Misc)

+(BOOL) isRunningFromPlugin
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] valueForKey:@"isKeyWindow"]) {
            return YES;
        }
    }
    
    return NO;
}

@end
