//
//  PodDetailPanel.h
//  CocoaPodsManager
//
//  Created by Andy on 04.04.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppConstants.h"
#import "PodSpec+Misc.h"

@interface PodDetailPanel : NSPanel

@property (nonatomic, copy) OnDone onDone;

-(void) displayPodSpec: (PodSpec *) pod;

@end
