//
//  EmoManager.h
//  ChatDemo-UI3.0
//
//  Created by EmoKit on 16/5/30.
//  Copyright © 2016年 zhan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMKEmoManager : NSObject

@property (nonatomic, strong)NSMutableDictionary *emoMessageDict;

+ (instancetype)shareInstance;

- (void)emoWithAMRFilePath:(NSString *)filePath messageModel:(id)model completionHandler:(void(^)(NSString *emo, BOOL finished))completionHandler;

/* 删除message的情绪
 param dataArray(EaseMessageModel对象)
 */
- (void)deleteMessageEmoWithArray:(NSArray *)dataArray;

@end
