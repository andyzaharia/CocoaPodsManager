//
//  Plugin.h
//  CocoaPodsPlugin
//
//  Created by Andrei Zaharia on 9/16/13.
//  Copyright (c) 2013 Andrei Zaharia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Plugin : NSObject
{
    NSString* selectedText;
}

@property (nonatomic, strong) NSMutableArray *windows;

+ (id)sharedPlugin;

+ (NSImage *) imageWithName: (NSString *) imageName;

-(void) clearWindow;

@end
