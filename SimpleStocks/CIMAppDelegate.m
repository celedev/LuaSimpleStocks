//
//  CIMAppDelegate.m
//  TouchCells
//
//  Created by Jean-Luc on 03/04/13.
//  Copyright (c) 2013 Celedev. All rights reserved.
//

#import "CIMAppDelegate.h"

#import "CIMLua/CIMLua.h"
#import "CIMLua/CIMLuaContextMonitor.h"

@interface DefautRootViewController : UIViewController
@end

@implementation CIMAppDelegate
{
    CIMLuaContext* _luaContext;
    CIMLuaContextMonitor* _luaContextMonitor;
    
    UIViewController* _viewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create a Lua Context for this application
    _luaContext = [[CIMLuaContext alloc] initWithName:@"Context"];
    _luaContextMonitor = [[CIMLuaContextMonitor alloc] initWithLuaContext:_luaContext connectionTimeout:10];
    
    // Create the application window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [DefautRootViewController new];
    
    // Run the code for this Lua context
    [_luaContext loadLuaModuleNamed:@"StockViewController" withCompletionBlock:^(Class viewControllerClass) {
        
        if ( [viewControllerClass isSubclassOfClass:[UIViewController class]])
        {
            _viewController = [viewControllerClass new];
            self.window.rootViewController = _viewController;
        }
    }];
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end

@implementation NSLocale (SimpleStock)

+ (NSLocale*) newWithIdentifier:(NSString *)string
{
    return [[self alloc] initWithLocaleIdentifier:string];
}

@end

@implementation DefautRootViewController

- (void) loadView 
{
    UIView* defaultRootView = [UIView new];
    defaultRootView.backgroundColor = UIColor.whiteColor;
    
    self.view = defaultRootView;
}

@end
