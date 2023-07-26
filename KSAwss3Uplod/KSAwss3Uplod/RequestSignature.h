//
//  RequestSignature.h
//  KSDemo
//
//  Created by Sun Xiaoxu on 2023/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestSignature : NSObject

+ (NSDictionary<NSString *, NSString *> *)signaturesWithHostString:(NSString *)hostString andActionString:(NSString *)actionString paramString:(NSString *)paramString secretId:(NSString *)secretId secretKey:(NSString *)secretKey deployVersion:(NSString *)deployVersion contentType:(NSString *)contentType;

@end

NS_ASSUME_NONNULL_END
