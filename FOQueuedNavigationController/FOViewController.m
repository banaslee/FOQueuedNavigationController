//
//  FOViewController.m
//  FOQueuedNavigationController
//
//  Created by Fábio Oliveira on 22/03/14.
//  Copyright (c) 2014 Fábio Oliveira. All rights reserved.
//

#import "FOViewController.h"

@interface FOViewController ()
@property (nonatomic, weak) IBOutlet UISlider *quantitySlider;
@property (nonatomic, weak) IBOutlet UILabel *quantityLabel;
@property (nonatomic, weak) IBOutlet UISwitch *animatedSwitch;
@end

@implementation FOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTouchPush:(id)sender {
    [self pushControllers:self.quantitySlider.value animated:self.animatedSwitch.isOn];
}

- (void)pushControllers:(NSUInteger)quantity animated:(BOOL)animated {
    for (int i = 0; i < quantity; i++) {
        FOViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FOViewController"];
        [self.navigationController pushViewController:viewController
                                             animated:animated];
    }
}

@end
