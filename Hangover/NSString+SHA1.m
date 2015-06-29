//
//  NSString+NSString_SHA1_m.m
//  Hangover
//
//  Created by Peter Sobot on 2015-05-30.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

#import "NSString+SHA1.h"
#import <CommonCrypto/CommonCrypto.h>
#import "objc/runtime.h"

@implementation NSData (SHA1)
- (NSString *) hexString
{
  NSUInteger bytesCount = self.length;
  if (bytesCount) {
    static char const *kHexChars = "0123456789abcdef";
    const unsigned char *dataBuffer = self.bytes;
    char *chars = malloc(sizeof(char) * (bytesCount * 2 + 1));
    char *s = chars;
    for (unsigned i = 0; i < bytesCount; ++i) {
      *s++ = kHexChars[((*dataBuffer & 0xF0) >> 4)];
      *s++ = kHexChars[(*dataBuffer & 0x0F)];
      dataBuffer++;
    }
    *s = '\0';
    NSString *hexString = [NSString stringWithUTF8String:chars];
    free(chars);
    return hexString;
  }
  return @"";
}

- (NSData *)sha1Hash
{
  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  if (CC_SHA1(self.bytes, (CC_LONG)self.length, digest)) {
    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
  }
  return nil;
}
@end

@implementation NSString (SHA1)

- (NSString *)SHA1
{
  NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
  NSData *hash = [data sha1Hash];
  return [hash hexString];
}

@end

void printKeyValuePairs(NSObject *self) {
    unsigned int outCount, i;

    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if (propName) {
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSLog(@"Property name: %@", propertyName);
        }
    }
    free(properties);
}
