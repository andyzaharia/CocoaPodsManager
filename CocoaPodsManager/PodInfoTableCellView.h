//
//  PodInfoTableCellView.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 4/11/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PodSpec.h"

@interface PodInfoTableCellView : NSTableCellView

@property (weak) IBOutlet NSTextField   *tfPodName;
@property (weak) IBOutlet NSTextField   *stPodDescription;
@property (weak) IBOutlet NSButton      *btnInstalled;

-(void) displayPodSpec: (PodSpec *) pod isInstalled: (BOOL) installed;

@end
