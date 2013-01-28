//
//  Created by Peyman Oreizy on 1/22/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import "NSString+DVJSONMapping.h"


static BOOL ShouldUppercaseWord(NSString *s)
{
  static NSArray *words = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    words = @[ @"http", @"url" ];
  });

  return [words containsObject:s.lowercaseString];
}

@implementation NSString (DVJSONMapping)

- (Class)dv_classify
{
  NSString *className = [[[self dv_camelString] dv_singularString] dv_sentenceCaseString];
  return NSClassFromString(className);
}

// Converts strings of the form "abc_def_ghi" into the form "abcDefGhi"
//
- (NSString *)dv_camelString;
{
  NSMutableString *result = [[NSMutableString alloc] init];

  NSArray *components = [self componentsSeparatedByString:@"_"];

  [components enumerateObjectsUsingBlock:^(NSString *s, NSUInteger idx, BOOL *stop) {
    if (idx > 0) {
      if (ShouldUppercaseWord(s)) {
        s = [s uppercaseString];
      }
      else {
        s = [s capitalizedString];
      }
    }
    [result appendString:s];
  }];

  return [NSString stringWithString:result];
}

- (NSString *)dv_pluralString;
{
  if ([self hasSuffix:@"s"]) {
    return self;
  }
  else {
    return [self stringByAppendingString:@"s"];
  }
}

- (NSString *)dv_sentenceCaseString;
{
  if (self.length == 0) {
    return nil;
  }

  NSString *first = [[self substringToIndex:1] uppercaseString];
  NSString *rest  = [self substringFromIndex:1];

  return [first stringByAppendingString:rest];
}

- (NSString *)dv_singularString;
{
  if ([self hasSuffix:@"ies"]) {
    NSString *s = [self substringToIndex:self.length - 3];
    return [s stringByAppendingString:@"y"];
  }
  if ([self hasSuffix:@"s"]) {
    return [self substringToIndex:self.length - 1];
  }
  else {
    return self;
  }
}

// Converts strings of the form "abcDefGhi" into "abc_def_ghi".
// Warning: It currently only supports the simple case of a lowercase letter followed
// by an uppercase letter, not number, not sequential uppercase letters, etc.
- (NSString *)dv_underscoreString;
{
  NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])" options:0 error:NULL];

  NSString *newString = [regexp stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"$1_$2"];

  newString = [newString lowercaseString];

  return newString;
}

@end
