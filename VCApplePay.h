//
//  VCApplePay.h
//  VCReadDemo
//
//  Created by tztddong on 16/9/23.
//  Copyright © 2016年 gyk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^PaySuccessedBlock)(NSString *receipt);
typedef void(^PayFailedBlock)(NSString *failedMessage);

@interface VCApplePay : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>

+ (instancetype)sharedApplePay;

/**
 *  使用单例或者实例对象调用
 *
 *  @param productID 产品的苹果ID 需要在ituns中预先设置
 *  @param PaySuccessedBlock 成功的回调
 *  @param PayFailedBlock    错误的回调
 */
- (void)startApplePayWithProductID:(NSString *)productID
                 PaySuccessedBlock:(PaySuccessedBlock)PaySuccessedBlock
                    PayFailedBlock:(PayFailedBlock)PayFailedBlock;

@property(nonatomic,copy)PaySuccessedBlock PaySuccessedBlock;
@property(nonatomic,copy)PayFailedBlock PayFailedBlock;

@end
