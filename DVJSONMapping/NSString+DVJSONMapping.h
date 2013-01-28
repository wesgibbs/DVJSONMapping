//
//  Created by Peyman Oreizy on 1/22/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DVJSONMapping)

- (Class)dv_classify;
- (NSString *)dv_camelString;
- (NSString *)dv_pluralString;
- (NSString *)dv_sentenceCaseString;
- (NSString *)dv_singularString;
- (NSString *)dv_underscoreString;

@end
