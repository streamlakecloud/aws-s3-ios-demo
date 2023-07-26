//
//  RequestSignature.m
//  KSDemo
//
//  Created by Sun Xiaoxu on 2023/7/12.
//

#import "RequestSignature.h"
#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>
#include <stdio.h>
#include <time.h>
#include <CommonCrypto/CommonCrypto.h>

using namespace std;

string get_data(int64_t &timestamp)
{
    string utcDate;
    char buff[20] = {0};
    // time_t timenow;
    struct tm sttime;
    time_t times_tamp = (time_t)timestamp;
    sttime = *std::gmtime(&times_tamp);
    strftime(buff, sizeof(buff), "%Y-%m-%d", &sttime);
    utcDate = string(buff);
    return utcDate;
}

string int2str(int64_t n)
{
    std::stringstream ss;
    ss << n;
    return ss.str();
}

string sha256Hex(const string &str)
{
    char buf[3];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX sha256;
    CC_SHA256_Init(&sha256);
    CC_SHA256_Update(&sha256, str.c_str(), (CC_LONG)str.size());
    CC_SHA256_Final(hash, &sha256);
    std::string NewString = "";
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
    {
        snprintf(buf, sizeof(buf), "%02x", hash[i]);
        NewString = NewString + buf;
    }
    return NewString;
}

string HmacSha256(const string &key, const string &input)
{
    unsigned char hash[32];
    CCHmac(kCCHmacAlgSHA256, &key[0], key.length(), ( unsigned char* )&input[0], input.length(), hash);
    
    unsigned int len = 32;
    std::stringstream ss;
    ss << std::setfill('0');
    for (int i = 0; i < len; i++)
    {
        ss  << hash[i];
    }

    return (ss.str());
}

string HexEncode(const string &input)
{
    static const char* const lut = "0123456789abcdef";
    size_t len = input.length();

    string output;
    output.reserve(2 * len);
    for (size_t i = 0; i < len; ++i)
    {
        const unsigned char c = input[i];
        output.push_back(lut[c >> 4]);
        output.push_back(lut[c & 15]);
    }
    return output;
}

@implementation RequestSignature

+ (NSDictionary *)signaturesWithHostString:(NSString *)hostString andActionString:(nonnull NSString *)actionString paramString:(nonnull NSString *)paramString secretId:(nonnull NSString *)secretId secretKey:(nonnull NSString *)secretKey deployVersion:(nonnull NSString *)deployVersion contentType:(nonnull NSString *)contentType {
    NSString *hostStr = [RequestSignature hostWithHostString:hostString];
    
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSInteger timeInterval = (NSInteger)nowTimeInterval;
    
    NSString *canonicalQueryStr = [NSString stringWithFormat:@"Action=%@", actionString];
    
    NSString *paramStr = paramString ?: @"";
    
    // 密钥参数
    // 需要设置环境变量 TENCENTCLOUD_SECRET_ID，值为示例的 AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******
    string SECRET_ID = string([secretId UTF8String]);// "07cf20fa134f49faa3253904d424d5c1";
    // 需要设置环境变量 TENCENTCLOUD_SECRET_KEY，值为示例的 Gu5t9xGARNpq86cd98joQYCN3*******
    string SECRET_KEY = string([secretKey UTF8String]); //"02d2b03835ad47e6a5540fcd0ee69d6f";

    string service = "vod";
    string host = string([hostStr UTF8String]);
    string region = "beijing";
    string action = string([actionString UTF8String]);
    string version = string([deployVersion UTF8String]);
    int64_t timestamp = int64_t(timeInterval);
    string date = get_data(timestamp);

    // ************* 步骤 1：拼接规范请求串 *************
    string httpRequestMethod = "POST";
    string canonicalUri = "/";
    string canonicalQueryString = string([canonicalQueryStr UTF8String]);
    string canonicalContentType = string([contentType UTF8String]);
    string canonicalHeaders = string("content-type:")
            + canonicalContentType
            + "\n"
            + "host:" + host;
    string signedHeaders = "content-type;host";
    string payload = string([paramStr UTF8String]);
    string hashedRequestPayload = sha256Hex(payload);
    string canonicalRequest = httpRequestMethod + "\n"
            + canonicalUri + "\n"
            + canonicalQueryString + "\n"
            + canonicalHeaders + "\n"
            + signedHeaders + "\n"
            + hashedRequestPayload;
    cout << canonicalRequest << endl;

    // ************* 步骤 2：拼接待签名字符串 *************
    string algorithm = "SL-HMAC-SHA256";
    string RequestTimestamp = int2str(timestamp);
    string credentialScope = date + "/" + service + "/" + "sl_request";
    string hashedCanonicalRequest = sha256Hex(canonicalRequest);
    string stringToSign = algorithm + "\n" + RequestTimestamp + "\n" + credentialScope + "\n" + hashedCanonicalRequest;
    cout << stringToSign << endl;

    // ************* 步骤 3：计算签名 ***************
    string kKey = "SL" + SECRET_KEY;
    string kDate = HmacSha256(kKey, date);
    string kService = HmacSha256(kDate, service);
    string kSigning = HmacSha256(kService, "sl_request");
    string signature = HexEncode(HmacSha256(kSigning, stringToSign));
    cout << signature << endl;

    // ************* 步骤 4：拼接 Authorization *************
    string authorization = algorithm + " " + "Credential=" + SECRET_ID + "/" + credentialScope + ", "
            + "SignedHeaders=" + signedHeaders + ", " + "Signature=" + signature + "sl_request";
    cout << authorization << endl;

    string curlcmd = "curl -X POST https://" + host + "/?Action=" + action + "\n"
                   + " -H \"Authorization: " + authorization + "\"\n"
                   + " -H \"Content-Type: " + canonicalContentType + "\"\n"
                   + " -H \"Host: " + host + "\"\n"
                   + " -H \"X-SL-Action: " + action + "\"\n"
                   + " -H \"X-SL-Timestamp: " + RequestTimestamp + "\"\n"
                   + " -H \"X-SL-Version: " + version + "\"\n"
                   + " -H \"X-SL-Region: " + region + "\"\n"
                   + " -H \"X-SL-Program-Language: C++\"" + "\n"
                   + " -H \"SignatureVersion: 1\"" + "\n"
                   + " -H \"AccessKey: " + SECRET_ID + "\"\n"
                   + " -d '" + payload + "\'";
    cout << curlcmd << endl;
    
    NSMutableDictionary<NSString *, NSString *> *signatures = [NSMutableDictionary dictionary];
    NSString *authorizationString = [NSString stringWithCString:authorization.c_str() encoding:NSUTF8StringEncoding];
    [signatures setObject:authorizationString forKey:@"Authorization"];
    
    [signatures setObject:contentType forKey:@"Content-Type"];
    
    [signatures setObject:hostStr forKey:@"Host"];
    
    [signatures setObject:actionString forKey:@"X-SL-Action"];
    
    NSString *requestTimestampString = [NSString stringWithCString:RequestTimestamp.c_str() encoding:NSUTF8StringEncoding];
    [signatures setObject:requestTimestampString forKey:@"X-SL-Timestamp"];
    
    NSString *versionString = [NSString stringWithCString:version.c_str() encoding:NSUTF8StringEncoding];
    [signatures setObject:versionString forKey:@"X-SL-Version"];
    
    NSString *regionString = [NSString stringWithCString:region.c_str() encoding:NSUTF8StringEncoding];
    [signatures setObject:regionString forKey:@"X-SL-Region"];
    
    [signatures setObject:@"IOS" forKey:@"X-SL-Program-Language"];
    
    [signatures setObject:@"1" forKey:@"SignatureVersion"];
    
    NSString *accessKeyString = [NSString stringWithCString:SECRET_ID.c_str() encoding:NSUTF8StringEncoding];
    [signatures setObject:accessKeyString forKey:@"AccessKey"];
    
    NSLog(@"签名: SECRET_ID:%@, SECRET_KEY:%@", secretId, secretKey);
    
//    NSLog(@"curl -X POST https://%@/?Action=%@\n \
//            -H \"Authorization: %@\"\n \
//            -H \"Content-Type: %@\"\n \
//            -H \"Host: %@\"\n \
//            -H \"X-SL-Action: %@\"\n \
//            -H \"X-SL-Timestamp: %@\"\n \
//            -H \"X-SL-Version: %@\"\n \
//            -H \"X-SL-Region: %@\"\n \
//            -H \"X-SL-Program-Language: %@\"\n \
//            -H \"SignatureVersion: %@\"\n \
//            -H \"AccessKey: %@\"\n \
//            -d \'%@\'",signatures[@"Host"], signatures[@"X-SL-Action"], signatures[@"Authorization"], signatures[@"Content-Type"], signatures[@"Host"], signatures[@"X-SL-Action"],signatures[@"X-SL-Timestamp"],signatures[@"X-SL-Version"],signatures[@"X-SL-Region"],signatures[@"X-SL-Program-Language"],signatures[@"SignatureVersion"],signatures[@"AccessKey"], paramString);

    return signatures;
}

+ (NSString *)hostWithHostString:(NSString *)hostString {
    NSString *host = [hostString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    return host;
}

@end
