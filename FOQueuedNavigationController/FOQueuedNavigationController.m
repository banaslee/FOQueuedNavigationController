//
//  FOQueuedNavigationController.m
//  FOQueuedNavigationController
//
//  Created by Fábio Oliveira on 22/03/14.
//  Copyright (c) 2014 Fábio Oliveira. All rights reserved.
//

#import "FOQueuedNavigationController.h"

#import <objc/runtime.h>

@interface FOQueuedNavigationController () <UINavigationControllerDelegate>
@property (nonatomic, weak) id<UINavigationControllerDelegate> originalDelegate;
@property (nonatomic) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *invocationQueue;
@end

@implementation FOQueuedNavigationController

#pragma mark - Class methods
/**
 * http://nshipster.com/method-swizzling/
 **/
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(setOriginalDelegate:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Instance methods
- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    
    return self;
}

- (NSMutableArray *)invocationQueue {
    if (!_invocationQueue) {
        _invocationQueue = [NSMutableArray array];
    }
    
    return _invocationQueue;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.isTransitioning) {
        NSMethodSignature *methodSignature = [NSMethodSignature methodSignatureForSelector:_cmd];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:self];
        [invocation setArgument:&viewController atIndex:0];
        [invocation setArgument:&@(animated) atIndex:1];
    }
    else {
        [super pushViewController:viewController animated:animated];
    }
}

#pragma mark Method Swizzling
- (void)setOriginalDelegate:(id<UINavigationControllerDelegate>)foDelegate {
    _originalDelegate = foDelegate;
}

#pragma mark - Protocols
#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isTransitioning = NO;
    
    if (self.originalDelegate && [self.originalDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.originalDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isTransitioning = YES;
    
    if (self.originalDelegate && [self.originalDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.originalDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
}

@end
