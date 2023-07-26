//
//  ViewController.m
//  KSAwss3Uplod
//
//  Created by Sun Xiaoxu on 2023/7/20.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MJExtension/MJExtension.h>
#import "Models.h"
#import <AWSS3/AWSS3.h>
#import "RequestSignature.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *applyUploadButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *applyUploadIndicatorView;
@property (weak, nonatomic) IBOutlet UITextView *appluUploadTextView;
@property (weak, nonatomic) IBOutlet UIButton *uploadButtton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadIndicatorView;
@property (weak, nonatomic) IBOutlet UITextView *uploadTextView;
@property (weak, nonatomic) IBOutlet UIButton *confirmUploadButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *confirmUploadIndicatorView;
@property (weak, nonatomic) IBOutlet UITextView *confirmUploadTextView;

@property (nonatomic, copy) NSString *filePath;/**< 预上传的文件路径 */
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;/**< 会话管理 */
@property (nonatomic, strong) ApplyUploadResult *applyUploadResult;
@property (nonatomic, strong) CommitUploadResult *commitUploadResult;;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)applyUploadButtonClicked:(UIButton *)sender {
    [self applyUpload];
}

- (IBAction)uploadButtonClicked:(UIButton *)sender {
    [self upload];
}

- (IBAction)confirmUploadButtonClicked:(UIButton *)sender {
    [self commitUpload];
}

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
        weakSelf.applyUploadButton.enabled = YES;
        [weakSelf.applyUploadIndicatorView stopAnimating];
        weakSelf.applyUploadResult = [ApplyUploadResult mj_objectWithKeyValues:responseObject];
        weakSelf.appluUploadTextView.text = weakSelf.applyUploadResult.mj_JSONString;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        weakSelf.applyUploadButton.enabled = YES;
        [weakSelf.applyUploadIndicatorView stopAnimating];
        NSLog(@"请求报错了");
    }];
    
    weakSelf.applyUploadButton.enabled = NO;
    [weakSelf.applyUploadIndicatorView startAnimating];
}

- (void)upload {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    
    AWSEndpoint *endPoint = [[AWSEndpoint alloc] initWithRegion:AWSRegionCNNorth1 service:AWSServiceS3 URL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", self.applyUploadResult.ResponseData.UploadAddress.UploadEndpoint]]];
    AWSBasicSessionCredentialsProvider *provider = [[AWSBasicSessionCredentialsProvider alloc] initWithAccessKey:self.applyUploadResult.ResponseData.UploadAuth.SecretId secretKey:self.applyUploadResult.ResponseData.UploadAuth.SecretKey sessionToken:self.applyUploadResult.ResponseData.UploadAuth.Token];
    AWSServiceConfiguration *config = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionCNNorth1 endpoint:endPoint credentialsProvider:provider];
    config.chunkedEncodingDisabled = YES;
    [AWSS3 registerS3WithConfiguration:config forKey:self.applyUploadResult.ResponseData.SessionKey];
    
    AWSS3 *server = [AWSS3 S3ForKey:self.applyUploadResult.ResponseData.SessionKey];
    
    AWSS3PutObjectRequest *request = [AWSS3PutObjectRequest new];
    NSData *body = [NSData dataWithContentsOfFile:self.filePath];
    request.body = body;
    request.contentType = @"video/mp4";
    request.key = self.applyUploadResult.ResponseData.UploadAddress.UploadPath;
    request.bucket = self.applyUploadResult.ResponseData.UploadAddress.StorageBucket;
    request.contentMD5 = [NSString aws_base64md5FromData:body];
    
    __weak typeof(self) weakSelf = self;
    [server putObject:request completionHandler:^(AWSS3PutObjectOutput * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"上传出错");
            weakSelf.uploadButtton.enabled = YES;
            [weakSelf.uploadIndicatorView stopAnimating];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.uploadTextView.text = @"成功";
                weakSelf.uploadButtton.enabled = YES;
                [weakSelf.uploadIndicatorView stopAnimating];
            });
        }
    }];
    
    self.uploadButtton.enabled = NO;
    [self.uploadIndicatorView startAnimating];
}

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
        weakSelf.confirmUploadTextView.text = weakSelf.commitUploadResult.mj_JSONString;
        weakSelf.confirmUploadButton.enabled = YES;
        [weakSelf.confirmUploadIndicatorView stopAnimating];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求报错了");
        weakSelf.confirmUploadButton.enabled = YES;
        [weakSelf.confirmUploadIndicatorView stopAnimating];
    }];
    
    self.confirmUploadButton.enabled = NO;
    [self.confirmUploadIndicatorView startAnimating];
}

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        AFJSONRequestSerializer *sessionRequest = [AFJSONRequestSerializer serializer];
        AFHTTPResponseSerializer *sessionResponse = [AFJSONResponseSerializer serializer];
        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
        sessionManager.requestSerializer = sessionRequest;
        sessionManager.responseSerializer = sessionResponse;
        
        _sessionManager = sessionManager;
    }
    
    return _sessionManager;
}

- (NSString *)filePath {
    if (!_filePath) {
        _filePath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    }
    
    return _filePath;
}

@end
