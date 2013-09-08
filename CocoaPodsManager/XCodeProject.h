//
//  XCodeProject.h
//  CocoaPodsManager
//
//  Created by Admin on 12.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface XCodeProject : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * projectFilePath;
@property (nonatomic, retain) NSDate * date;

@end
