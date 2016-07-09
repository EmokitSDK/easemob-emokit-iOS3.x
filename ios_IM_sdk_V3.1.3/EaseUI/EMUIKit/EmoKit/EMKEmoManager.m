//
//  EmoManager.m
//  ChatDemo-UI3.0
//
//  Created by EmoKit on 16/5/30.
//  Copyright © 2016年 zhan. All rights reserved.
//

#import "EMKEmoManager.h"
#import "EMKOpenUDID.h"
#import "EaseMessageModel.h"

#define kEmoMessageKey @"EmoMessageKey"
#define EmoKitAudioURL @"http://api-web.emokit.com:802/wechatemo/WxVoiceamr.do"

@interface EMKEmoManager ()

@property(nonatomic, copy)NSString  *appKey;
@property(nonatomic, copy)NSString  *appId;
@property(nonatomic, strong)NSDictionary *emoResultDictionary;

@end

@implementation EMKEmoManager

+ (instancetype)shareInstance
{
    static EMKEmoManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EMKEmoManager alloc] init];
        manager.emoResultDictionary = @{@"K": @"平静；放松；专注；出神",
                                        @"D": @"忧愁；疑惑；迷茫；无助",
                                        @"C": @"伤感；郁闷；痛心；压抑",
                                        @"Y": @"生气；失控；兴奋；宣泄",
                                        @"M": @"开心；甜蜜；欢快；舒畅",
                                        @"W": @"害怕；焦虑；紧张；激情",
                                        @"T": @"厌恶；反感；意外；惊讶",};
        
        NSDictionary *emoDic = [[NSUserDefaults standardUserDefaults] objectForKey:kEmoMessageKey];
        if (!emoDic)
            manager.emoMessageDict = [[NSMutableDictionary alloc] init];
        else
            manager.emoMessageDict = [NSMutableDictionary dictionaryWithDictionary:emoDic];
    });
    
    return manager;
}

+ (void)startAppKey:(NSString *)appKey AppId:(NSString *)appId
{
    [EMKEmoManager shareInstance].appKey = appKey;
    [EMKEmoManager shareInstance].appId = appId;
}

- (void)requestEmoWithAudioData:(NSData *)data messageModel:(id)model completionHandler:(void(^)(NSString *emo, BOOL finished))completionHandler
{
    NSMutableDictionary *paramDic = [[NSMutableDictionary alloc] init];
    [paramDic setObject:self.appId forKey:@"appid"];
    [paramDic setObject:self.appKey forKey:@"key"];
    [paramDic setObject:@"iOS huanxin" forKey:@"platid"];
    [paramDic setObject:[EMKOpenUDID value] forKey:@"uid"];
    [paramDic setObject:@"2" forKey:@"type  "];
    [paramDic setObject:data forKey:@"file"];
    
    
    NSString *TWITTERFON_FORM_BOUNDARY = @"AaB03x";
    //分界线 --AaB03x
    NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
    //结束符 AaB03x--
    NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
    //http body的字符串
    NSMutableString *body=[[NSMutableString alloc]init];
    //参数的集合的所有key的集合
    //遍历keys
    for(int i = 0; i < [paramDic count]; i++)
    {
        //得到当前key
        NSString *key=[paramDic.allKeys objectAtIndex:i];
        //如果key不是file，说明value是字符类型，比如name：Boris
        if (![key isEqualToString:@"file"])
        {
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            //添加字段名称，换2行
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
            //添加字段的值
            [body appendFormat:@"%@\r\n",[paramDic objectForKey:key]];
        }
    }
    
    ////添加分界线，换行
    [body appendFormat:@"%@\r\n",MPboundary];
    //声明file字段，文件名为boris.amr
    [body appendFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"boris.amr\"\r\n"];
    //声明上传文件的格式
    [body appendFormat:@"Content-Type: application/octet-stream\r\n\r\n"];
    
    //声明结束符：--AaB03x--
    NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
    //声明myRequestData，用来放入http body
    NSMutableData *bodyData = [NSMutableData data];
    //将body字符串转化为UTF8格式的二进制
    [bodyData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    //将image的data加入
    [bodyData appendData:data];
    //加入结束符--AaB03x--
    [bodyData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:EmoKitAudioURL]];
    //设置HTTPHeader中Content-Type的值
    NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
    //设置HTTPHeader
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
    
    //设置Content-Length
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    
    request.HTTPMethod = @"POST";
    [request setHTTPBody:bodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                
                                                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                                
                                                NSString *emo = nil;
                                                NSDictionary *infoVoiceDic = result[@"infovoice"];
                                                if (infoVoiceDic[@"rc_main"])
                                                {
                                                    NSString *rc_main = infoVoiceDic[@"rc_main"];
                                                    emo = [self.emoResultDictionary[rc_main] substringToIndex:2];
                                                }
                                                else
                                                {
                                                    emo = @"--";
                                                }
                                                
                                                if ([model isKindOfClass:[EaseMessageModel class]])
                                                {
                                                    EaseMessageModel *messageModel = (EaseMessageModel *)model;
                                                    messageModel.emoFromEmoKit = emo;
                                                    
                                                    // 记录EaseMessageModel的表情
                                                    NSString *messageKey = [NSString stringWithFormat:@"%@", [[messageModel.fileLocalPath lastPathComponent] stringByDeletingPathExtension]];
                                                    [self.emoMessageDict setObject:emo forKey:messageKey];
                                                    [[NSUserDefaults standardUserDefaults] setObject:self.emoMessageDict forKey:kEmoMessageKey];
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    completionHandler(emo, YES);
                                                });
                                            }];
    [task resume];
}

- (void)emoWithAMRFilePath:(NSString *)filePath messageModel:(id)model completionHandler:(void(^)(NSString *emo, BOOL finished))completionHandler;
{
    NSData *amrFileData = [[NSFileManager defaultManager] contentsAtPath:filePath];
    [self requestEmoWithAudioData:amrFileData
                     messageModel:model
                completionHandler:^(NSString *emo, BOOL finished) {
                    
                    completionHandler(emo, YES);
                }];
}

- (void)deleteMessageEmoWithArray:(NSArray *)dataArray
{
    for (int i = 0; i < [dataArray count]; i++)
    {
        id model = dataArray[i];
        if ([model isKindOfClass:[EaseMessageModel class]])
        {
            EaseMessageModel *messageModel = (EaseMessageModel *)model;
            NSString *messageKey = [NSString stringWithFormat:@"%@", [[messageModel.fileLocalPath lastPathComponent] stringByDeletingPathExtension]];
            [self.emoMessageDict removeObjectForKey:messageKey];
        }
    }
}

@end
