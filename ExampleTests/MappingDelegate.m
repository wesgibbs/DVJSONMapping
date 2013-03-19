//
//  MappingDelegate.m
//  Example
//
//  Created by Peyman Oreizy on 3/18/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import "MappingDelegate.h"

@implementation MappingDelegate

- (NSSet *)JSONMapping:(DVJSONMapping *)mapping willRemoveObjects:(NSSet *)objects fromRelationship:(NSRelationshipDescription *)relationship ofObject:(id)object
{
  NSMutableSet *objectsToKeep = [[NSMutableSet alloc] init];

  [objects enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    if ([obj respondsToSelector:@selector(id)]) {
      if ([obj performSelector:@selector(id)] == nil) {
        [objectsToKeep addObject:obj];
      }
    }
  }];

  return objectsToKeep;
}

@end
