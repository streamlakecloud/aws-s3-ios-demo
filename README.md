# AWS SDK upload demo for iOS
本项目是一个示例实现， 使用aws-sdk-ios，实现客户端上传到兼容 Amazon Web Services (AWS) 的 Simple Storage Service (S3)协议的StreamLake媒体存储功能.

## Getting started
但是由于StreamLake的存储协议与aws有稍许差异，所以对aws-sdk-ios的库做了少许修改。请使用（https://git.corp.kuaishou.com/streamlake/client-sdk/s3） 版本
引入方式：
```groovy
pod 'AWSCore', :git=>'git@git.corp.kuaishou.com:streamlake/client-sdk/s3.git', :branch=>'develop'
pod 'AWSS3', :git=>'git@git.corp.kuaishou.com:streamlake/client-sdk/s3.git', :branch=>'develop'
```

## 接口签名
请求StreamLake接口需要签名才能正确访问服务器，接口签名用的是AWS的标准
签名的实现类为[RequestSignature](./KSAwss3Uplod/KSAwss3Uplod/RequestSignature.mm)

## 上传步骤
使用aws-sdk-iOS上传到StreamLake媒体存储，主要分为三步串行
代码示例参考[PreviewController](./KSAwss3Uplod/KSAwss3Uplod/ViewController.m)

### 申请上传
调用ApplyUploadInfo接口，curl描述如下，其中AccessKey为StreamLake颁发的用户唯一身份凭证
```bash
curl --location 'vod.streamlakeapi.com/?Action=ApplyUploadInfo' \
--header 'AccessKey: ${custom_accesskey}' \
--header 'Content-Type: application/json' \
--data '{
    "FilePath": "test.mp4",
    "Format": "mp4"
}
```

返回ApplyUploadInfo数据结构如下
```json
{
    "ResponseMeta": {
        "RequestId": "ClonG2SuiT4AAAAAAABOzA", 
        "ErrorCode": "0", 
        "ErrorMessage": "success"
    }, 
    "ResponseData": {
        "SessionKey": "ClonG2SuiT4AAAAAAABOzA1689221470", 
        "UploadAddress": {
            "StorageBucket": "sl-a07ff17534a71cd495", 
            "Region": "cn-beijing", 
            "UploadEndpoint": "kms-cn-beijing.streamlakeapi.com", 
            "UploadPath": "media/ClonG2SuiT4AAAAAAABOzA1689221470/video:6926.mp4"
        }, 
        "UploadAuth": {
            "SecretId": "", 
            "SecretKey": "", 
            "Token": "", 
            "ExpiredTime": 1689225070690
        }
    }
}
```

接口调用示例
```Objective-C
/// 请求上传
- (void)applyUpload {
    NSString *url = @"https://vod.streamlakeapi.com/?Action=ApplyUploadInfo";
    
    NSDictionary *parameters = @{
        @"FilePath" : self.filePath,
        @"Format" : @"mp4"
    };
    
    NSDictionary *headers = [RequestSignature signaturesWithHostString:@"https://vod.streamlakeapi.com" andActionString:@"ApplyUploadInfo" paramString:parameters.mj_JSONString secretId:@"b44275774f4b4aa39af012363e7d7689" secretKey:@"a8c4ad8b10964a2e9f3385fbb545cd57" deployVersion:@"0.0.1" contentType:@"application/json"];
    
    __weak typeof(self) weakSelf = self;
    [self.sessionManager POST:url parameters:parameters headers:headers progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        weakSelf.applyUploadResult = [ApplyUploadResult mj_objectWithKeyValues:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求报错了");
    }];
}
```

### 开始上传
拿到上传凭证后，调用aws-android-sdk-s3开始上传

```Objective-C
AWSEndpoint *endPoint = [[AWSEndpoint alloc] initWithRegion:AWSRegionCNNorth1 service:AWSServiceS3 URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", applyUploadResult.ResponseData.UploadAddress.UploadEndpoint]]];
AWSBasicSessionCredentialsProvider *provider = [[AWSBasicSessionCredentialsProvider alloc] initWithAccessKey:applyUploadResult.ResponseData.UploadAuth.SecretId secretKey:applyUploadResult.ResponseData.UploadAuth.SecretKey sessionToken:applyUploadResult.ResponseData.UploadAuth.Token];
AWSServiceConfiguration *config = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionCNNorth1 endpoint:endPoint credentialsProvider:provider];
config.chunkedEncodingDisabled = YES;
[AWSS3 registerS3WithConfiguration:config forKey:applyUploadResult.ResponseData.SessionKey];

AWSS3 *server = [AWSS3 S3ForKey:applyUploadResult.ResponseData.SessionKey];

AWSS3PutObjectRequest *request = [AWSS3PutObjectRequest new];
NSData *body = [NSData dataWithContentsOfFile:self.filePath];
request.body = body;
request.contentType = @"video/mp4";
request.key = applyUploadResult.ResponseData.UploadAddress.UploadPath;
request.bucket = applyUploadResult.ResponseData.UploadAddress.StorageBucket;
request.contentMD5 = [NSString aws_base64md5FromData:body];

__weak typeof(self) weakSelf = self;
[server putObject:request completionHandler:^(AWSS3PutObjectOutput * _Nullable response, NSError * _Nullable error) {
    if (error) {
        NSLog(@"上传出错");
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
        
        });
    }
}];
```

### 确认上传
上传完成后，调用确认上传CommitUpload接口，curl描述如下

代码示例参考 [UploadApiService.kt](./app/src/main/java/com/kwai/upload/demo/network/UploadApiService.kt)
```bash
curl --location 'vod.streamlakeapi.com/?Action=CommitUpload' \
--header 'AccessKey: ${access_key}' \
--header 'Content-Type: application/json' \
--data '{
    "SessionKey": "nv4o2hedf8h89h2"
}'
```
确认上传成功返回接口如下，其中MediaId为唯一媒资ID，可根据MediaId获取媒资的播放url或多码率媒资数据
```json
{
    "ResponseMeta": {
        "RequestId": "ClonG2SuiT4AAAAAAABOzw", 
        "ErrorCode": "0", 
        "ErrorMessage": "success"
    }, 
    "ResponseData": {
        "MediaId": "eb207b7795d138f0", 
        "MediaSort": "media", 
        "FileUrl": ""
    }
}
```
接口调用示例
```Objective-C
/// 确认上传
- (void)commitUpload {
    NSString *url = @"https://vod.streamlakeapi.com/?Action=CommitUpload";
    
    NSDictionary *parameters = @{
        @"SessionKey" : self.applyUploadResult.ResponseData.SessionKey,
    };
    
    NSDictionary *headers = [RequestSignature signaturesWithHostString:@"https://vod.streamlakeapi.com" andActionString:@"CommitUpload" paramString:parameters.mj_JSONString secretId:@"b44275774f4b4aa39af012363e7d7689" secretKey:@"a8c4ad8b10964a2e9f3385fbb545cd57" deployVersion:@"0.0.1" contentType:@"application/json"];
    
    __weak typeof(self) weakSelf = self;
    [self.sessionManager POST:url parameters:parameters headers:headers progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        weakSelf.commitUploadResult = [CommitUploadResult mj_objectWithKeyValues:responseObject];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求报错了");
    }];
}
```
