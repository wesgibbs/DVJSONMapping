//
//  Created by Peyman Oreizy on 1/31/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import "JSONData.h"

@implementation JSONData

+ (NSDictionary *)newYorkCityTripJSON
{
  const NSString *kJSON = @"{\
    'trip': {\
      'id': 301,\
      'name': 'NYC',\
      'duration': 10,\
      'is_draft': true,\
      'last_modified': '2012-04-29T02:27:01Z',\
      'description': 'A list of places in New York City',\
      'places': [\
        {\
          'id': '1114c1734fcb',\
          'name': 'Empire State Building',\
          'address': '350 W 34th St, New York, NY 10118'\
        }, {\
          'id': '2224c1734fcb',\
          'name': 'Grand Central Station',\
          'address': '15 Vanderbilt Avenue, New York, NY 10017'\
        }, {\
          'id': '3334c1734fcb',\
          'name': 'New York Grand Central Library',\
          'address': '135 East 46th Street, New York, NY 10017'\
        }\
      ]\
    }\
  }";

  NSString *jsonString = [kJSON stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
}

+ (NSDictionary *)threeTripsJSON
{
  const NSString *kJSON = @"{\
    'trips': [{\
      'id': 301,\
      'name': 'NYC',\
      'duration': 10,\
      'is_draft': true,\
      'last_modified': '2012-04-29T02:27:01Z',\
      'description': 'A list of places in New York City',\
      'places': [\
        {\
          'id': '1114c1734fcb',\
          'name': 'Empire State Building',\
          'address': '350 W 34th St, New York, NY 10118'\
        }, {\
          'id': '2224c1734fcb',\
          'name': 'Grand Central Station',\
          'address': '15 Vanderbilt Avenue, New York, NY 10017'\
        }, {\
          'id': '3334c1734fcb',\
          'name': 'New York Grand Central Library',\
          'address': '135 East 46th Street, New York, NY 10017'\
        }\
      ]\
    }, {\
      'id': 302,\
      'name': 'San Francisco',\
      'duration': 5,\
      'is_draft': false,\
      'last_modified': '2012-05-29T02:27:01Z',\
      'description': 'A list of places in San Francisco',\
      'places': [\
        {\
          'id': '11',\
          'name': 'China Town',\
          'address': ''\
        }, {\
          'id': '22',\
          'name': 'Golden Gate Bridge',\
          'address': ''\
        }, {\
          'id': '33',\
          'name': 'Coit Tower',\
          'address': ''\
        }\
      ]\
    }, {\
      'id': 303,\
      'name': 'Seattle',\
      'duration': 7,\
      'is_draft': false,\
      'last_modified': '2013-05-29T02:27:01Z',\
      'description': 'A list of places in Seattle',\
      'places': [\
        {\
          'id': 800,\
          'name': 'Space Needle',\
          'address': ''\
        }, {\
          'id': 801,\
          'name': 'Pike Place Market',\
          'address': ''\
        }, {\
          'id': 802,\
          'name': 'Smith Tower',\
          'address': ''\
        }\
      ]\
    }]\
  }";

  NSString *jsonString = [kJSON stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
}

@end
