//
//  VCApplePay.m
//  VCReadDemo
//
//  Created by tztddong on 16/9/23.
//  Copyright © 2016年 gyk. All rights reserved.
//

#import "VCApplePay.h"
#import "NSData+MKBase64.h"

static VCApplePay *applePay = nil;

@implementation VCApplePay

+ (instancetype)sharedApplePay{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        applePay = [[VCApplePay alloc]init];
    });
    return applePay;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)startApplePayWithProductID:(NSString *)productID PaySuccessedBlock:(PaySuccessedBlock)PaySuccessedBlock PayFailedBlock:(PayFailedBlock)PayFailedBlock{
    
    self.PaySuccessedBlock = PaySuccessedBlock;
    self.PayFailedBlock = PayFailedBlock;
    
    if ([SKPaymentQueue canMakePayments]) {
        
        [self getProductInfoWithProductID:productID];
    } else {

        if (self.PayFailedBlock) {
            self.PayFailedBlock(@"用户禁止应用内付费购买");
        }
    }
}

// 下面的ProductId应该是事先在itunesConnect中添加好的，已存在的付费项目。否则查询会失败。
- (void)getProductInfoWithProductID:(NSString *)productID {
    NSSet * set = [NSSet setWithArray:@[productID]];
    SKProductsRequest * request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    request.delegate = self;
    [request start];
}

// 以上查询的回调函数
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *myProduct = response.products;
    if (myProduct.count == 0) {
        if (self.PayFailedBlock) {
            self.PayFailedBlock(@"无法获取产品信息，购买失败");
        }
        return;
    }
    SKPayment * payment = [SKPayment paymentWithProduct:myProduct[0]];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
                NSLog(@"transactionIdentifier = %@", transaction.transactionIdentifier);
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing://商品添加进列表
                NSLog(@"商品添加进列表");
                break;
            default:
                break;
        }
    }
    
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    // Your application should implement these two methods.
    NSString * productIdentifier = transaction.payment.productIdentifier;
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString * receipt = [receiptData base64EncodedString];
    if ([productIdentifier length] > 0) {
        // 向自己的服务器验证购买凭证
        if (self.PaySuccessedBlock) {
            self.PaySuccessedBlock(receipt);
        }
    }
    
    // Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        
        if (self.PayFailedBlock) {
            self.PayFailedBlock(@"购买失败");
        }
    } else {
        
        if (self.PayFailedBlock) {
            self.PayFailedBlock(@"用户取消交易");
        }
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    if (self.PayFailedBlock) {
        self.PayFailedBlock(@"此商品已购买");
    }
    // 对于已购商品，处理恢复购买的逻辑
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
