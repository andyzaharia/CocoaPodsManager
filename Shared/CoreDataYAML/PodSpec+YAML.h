//
//  PodSpec+YAML.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 4/4/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec.h"

@interface PodSpec (YAML)

-(NSDictionary *) authorsFromYAML: (NSMutableArray *) yaml;
-(NSString *) nameFromYAML: (NSMutableArray *) yaml;
-(NSString *) platformsFromYAML: (NSMutableArray *) yaml;
-(NSString *) licenseFromYAML: (NSMutableArray *) yaml;
-(NSString *) sourceFromYAML: (NSMutableArray *) yaml;
-(NSString *) summaryFromYAML: (NSMutableArray *) yaml;
-(NSString *) descriptionFromYAML: (NSMutableArray *) yaml;
-(NSString *) homepageFromYAML: (NSMutableArray *) yaml;

@end
