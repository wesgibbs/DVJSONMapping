//
//  Created by Peyman Oreizy on 2/16/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import "DVJSONMapping.h"

@interface DVJSONMapping (Internal)

- (NSError *)errorWithCode:(NSInteger)code,...;

- (ISO8601DateFormatter *)iso8601DateFormatter;

- (void)logWarning:(NSString *)string;

- (id)mapJSONObject:(NSDictionary *)aJSONObject ofClass:(Class)aClass error:(NSError **)errorPtr;

@end