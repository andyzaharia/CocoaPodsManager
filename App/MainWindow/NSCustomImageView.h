//
//  NSCustomImageView.h
//  CocoaPodsManager
//
//  Created by Admin on 12.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^OnFileDrop)(NSString *filePath);

@interface NSCustomImageView : NSImageView

@property (nonatomic, copy) OnFileDrop onFileDropBlock;

@end
