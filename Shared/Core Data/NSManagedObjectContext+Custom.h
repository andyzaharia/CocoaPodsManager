//
//  NSManagedObjectContext+Custom.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/18/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Custom)

+ (NSManagedObjectContext *) contextForMainThread;
+ (NSManagedObjectContext *) contextForCurrentThread;
+ (void) cleanContextsForCurrentThread;



@end
