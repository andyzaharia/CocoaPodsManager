//
//  AppConstants.h
//  CocoaPodsManager
//
//  Created by Admin on 23.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OnDone)(void);
typedef void (^OnFailure)(NSString *message);
typedef void (^OnProgress)(CGFloat progress);

extern NSString * const PODS_STATISTICS_YAML_FILE;
extern NSString * const PODS_MASTER_FOLDER;

extern NSString * const PODS_NOT_INSTALLED_MESSAGE;
extern NSString * const PODS_NOT_INSTALLED_LABEL;