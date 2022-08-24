//
//  utils.m
//  multicast_bytecopy
//
//  Created by apple on 2022/8/24.
//

#import <Foundation/Foundation.h>

void LOG(NSString *log) {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"updateLog" object:nil userInfo:@{@"logs": log}];
}
