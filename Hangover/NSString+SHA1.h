//
//  NSString+NSString_SHA1_m.h
//  Hangover
//
//  Created by Peter Sobot on 2015-05-30.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SHA1)
- (NSString *)SHA1;
@end

void printKeyValuePairs(NSObject *self);
CGFloat heightForAttributedString(NSAttributedString *attrString, CGFloat inWidth);