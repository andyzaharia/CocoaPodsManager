//
//  AppConstants.h
//  CocoaPodsManager
//
//  Created by Admin on 23.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OnDone)(void);
typedef void (^OnDoneEx)(id data);
typedef void (^OnFailure)(NSString *message);
typedef void (^OnProgress)(CGFloat progress);
typedef void (^OnSuccess) (NSString *);
typedef void (^OnError) (NSError *);

extern NSString * const PODS_STATISTICS_YAML_FILE;
extern NSString * const PODS_MASTER_FOLDER;

extern NSString * const PODS_NOT_INSTALLED_MESSAGE;
extern NSString * const PODS_NOT_INSTALLED_LABEL;

extern NSString * const CHANGELOG_URL_STR;
extern NSString * const COCOAPODS_LASTEST_VERSION_YAML;
