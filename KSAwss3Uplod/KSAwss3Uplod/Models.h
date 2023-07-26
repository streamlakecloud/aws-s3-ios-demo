//
//  Models.h
//  KSDemo
//
//  Created by Sun Xiaoxu on 2023/7/12.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

NS_ASSUME_NONNULL_BEGIN

@class ResponseMeta;
@class ApplyResponseData;

@interface ApplyUploadResult : NSObject

@property (nonatomic, strong) ResponseMeta *ResponseMeta;
@property (nonatomic, strong) ApplyResponseData *ResponseData;

@end

@interface ResponseMeta : NSObject

@property (nonatomic, copy) NSString *RequestId;
@property (nonatomic, copy) NSString *ErrorCode;
@property (nonatomic, copy) NSString *ErrorMessage;

@end

@class UploadAddress;
@class UploadAuth;

@interface ApplyResponseData : NSObject

@property (nonatomic, copy) NSString *SessionKey;
@property (nonatomic, strong) UploadAddress *UploadAddress;
@property (nonatomic, strong) UploadAuth *UploadAuth;

@end

@interface UploadAddress : NSObject

@property (nonatomic, copy) NSString *StorageBucket;
@property (nonatomic, copy) NSString *Region;
@property (nonatomic, copy) NSString *UploadEndpoint;
@property (nonatomic, copy) NSString *UploadPath;

@end

@interface UploadAuth : NSObject

@property (nonatomic, copy) NSString *SecretId;
@property (nonatomic, copy) NSString *SecretKey;
@property (nonatomic, copy) NSString *Token;
@property (nonatomic, assign) NSTimeInterval ExpiredTime;

@end


@class CommitResponseData;

@interface CommitUploadResult : NSObject

@property (nonatomic, strong) ResponseMeta *ResponseMeta;
@property (nonatomic, strong) CommitResponseData *ResponseData;

@end

@interface CommitResponseData : NSObject

@property (nonatomic, copy) NSString *MediaId;
@property (nonatomic, copy) NSString *MediaSort;

@end

NS_ASSUME_NONNULL_END
