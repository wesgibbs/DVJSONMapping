//
//  Place.h
//  Example
//
//  Created by Peyman Oreizy on 1/27/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Place : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSManagedObject *trip;

@end
