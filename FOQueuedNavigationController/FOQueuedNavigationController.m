//
//  FOQueuedNavigationController.m
//  FOQueuedNavigationController
//
//  Created by Fábio Oliveira on 22/03/14.
//  Copyright (c) 2014 Fábio Oliveira. All rights reserved.
//

#import "FOQueuedNavigationController.h"

#import <objc/runtime.h>

#define DEFAULT_TIMEOUT 1.f

typedef BOOL (^InvocationBlock)(void);
@interface FOQueuedNavigationController () <UINavigationControllerDelegate>
@property (nonatomic, weak) id<UINavigationControllerDelegate> originalDelegate;
@property (nonatomic, weak) id<UINavigationControllerDelegate> delegate;
@property (nonatomic) BOOL isTransitioning;
@property (nonatomic, strong) NSMutableArray *invocationQueue;
@end

@implementation FOQueuedNavigationController

@synthesize delegate = _delegate;

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
#pragma mark Overrides
- (void)commonInitializer {
    _delegate = self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass {
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self commonInitializer];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInitializer];
    }
    
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self commonInitializer];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitializer];
    }
    
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInitializer];
    }
    
    return self;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated {
    [self pushViewController:viewController
                    animated:animated
                 withTimeout:DEFAULT_TIMEOUT];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    return [self popToRootViewControllerAnimated:animated
                                     withTimeout:DEFAULT_TIMEOUT];
}

- (NSArray *)popToViewController:(UIViewController *)viewController
                        animated:(BOOL)animated {
    return [self popToViewController:viewController
                            animated:animated
                         withTimeout:DEFAULT_TIMEOUT];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    return [self popViewControllerAnimated:animated
                               withTimeout:DEFAULT_TIMEOUT];
}

#pragma mark Enqueuing
- (NSMutableArray *)invocationQueue {
    if (!_invocationQueue) {
        _invocationQueue = [NSMutableArray array];
    }
    
    return _invocationQueue;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
               withTimeout:(NSTimeInterval)timeout {
    if (self.isTransitioning) {
        NSDate *limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout];
        
        void(^block)(void) = ^{
            if ([[NSDate date] compare:limitTime] != NSOrderedDescending) {
                [self pushViewController:viewController
                                animated:animated];
            }
        };
        
        [self.invocationQueue addObject:block];
    }
    else {
        [super pushViewController:viewController
                         animated:animated];
    }
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
                                 withTimeout:(NSTimeInterval)timeout {
    if (self.isTransitioning) {
        NSDate *limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout];
        
        InvocationBlock block = ^{
            if ([[NSDate date] compare:limitTime] != NSOrderedDescending) {
                [self popToRootViewControllerAnimated:animated];
                
                return YES;
            }
            else {
                return NO;
            }
        };
        
        [self.invocationQueue addObject:block];
        
        return nil;
    }
    else {
        return [super popToRootViewControllerAnimated:animated];
    }
}

- (NSArray *)popToViewController:(UIViewController *)viewController
                        animated:(BOOL)animated
                     withTimeout:(NSTimeInterval)timeout {
    if (self.isTransitioning) {
        NSDate *limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout];
        
        void(^block)(void) = ^{
            if ([[NSDate date] compare:limitTime] != NSOrderedDescending) {
                [self popToViewController:viewController
                                 animated:animated];
            }
        };
        
        [self.invocationQueue addObject:block];
        
        return nil;
    }
    else {
        return [super popToViewController:viewController
                                 animated:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated withTimeout:(NSTimeInterval)timeout {
    if (self.isTransitioning) {
        NSDate *limitTime = [NSDate dateWithTimeIntervalSinceNow:timeout];
        
        void(^block)(void) = ^{
            if ([[NSDate date] compare:limitTime] != NSOrderedDescending) {
                [self popViewControllerAnimated:animated];
            }
        };
        
        [self.invocationQueue addObject:block];
        
        return nil;
    }
    else {
        return [super popViewControllerAnimated:animated];
    }
}

#pragma mark Method Swizzling
- (void)setOriginalDelegate:(id<UINavigationControllerDelegate>)originalDelegate {
    _originalDelegate = originalDelegate;
}

#pragma mark - Protocols
#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    self.isTransitioning = NO;
    
    if (self.originalDelegate && [self.originalDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.originalDelegate navigationController:navigationController
                              didShowViewController:viewController
                                           animated:animated];
    }
    
    BOOL executed;
    
    do {
        InvocationBlock block = self.invocationQueue.firstObject;
        if (block) {
            executed = block();
            [self.invocationQueue removeObject:block];
        }
        else {
            executed = YES;
        }
    } while (!executed);
    
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    self.isTransitioning = YES;
    
    if (self.originalDelegate && [self.originalDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.originalDelegate navigationController:navigationController
                             willShowViewController:viewController
                                           animated:animated];
    }
}

@end
