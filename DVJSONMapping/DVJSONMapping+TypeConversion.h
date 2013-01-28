//
//  Created by Peyman Oreizy on 1/26/13.
//  Copyright 2013 Dynamic Variable LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "DVJSONMapping.h"

@interface DVJSONMapping (TypeConversion)

- (void)assignJSONValue:(id)jsonValue toAttribute:(NSAttributeDescription *)attribute ofObject:(id)object;
- (void)assignJSONValue:(id)jsonValue toRelationship:(NSRelationshipDescription *)relationship ofObject:(id)object error:(NSError **)errorPtr;

- (void)assignObjectValue:(id)value ofAttribute:(NSAttributeDescription *)attribute toJSON:(NSMutableDictionary *)json error:(NSError **)errorPtr;
- (void)assignObjectValue:(id)objectValue ofRelationship:(NSRelationshipDescription *)relationship onlyChanges:(BOOL)onlyChanges toJSON:(NSMutableDictionary *)json error:(NSError **)errorPtr;

@end
