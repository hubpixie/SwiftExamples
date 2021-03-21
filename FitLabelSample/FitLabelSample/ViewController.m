//
//  ViewController.m
//  FitLabelSample
//
//  Created by venus.janne on 2017/12/07.
//  Copyright © 2017 venus.janne. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textFieldFit1;
@property (weak, nonatomic) IBOutlet UITextField *textFieldFit2;
@property (weak, nonatomic) IBOutlet UILabel *labelFit1;
@property (weak, nonatomic) IBOutlet UILabel *labelFit2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapButtonFit1:(UIButton *)sender {
    self.labelFit1.text = self.textFieldFit1.text;
    self.labelFit1.numberOfLines = 0;
    self.labelFit1.lineBreakMode = NSLineBreakByWordWrapping;
    self.labelFit1.font = [UIFont systemFontOfSize:13.0];
    CGRect frame = self.labelFit1.frame;
    frame = CGRectMake(frame.origin.x, frame.origin.y, 244, 1);
    CGSize size = [self.labelFit1 sizeThatFits:CGSizeMake(frame.size.width, CGFLOAT_MAX)];
    frame.size.height = size.height;
    self.labelFit1.frame = frame;
    printf("tapButtonFit1 - height = %f, %f\n", self.labelFit1.frame.size.width, self.labelFit1.frame.size.height);
}
- (IBAction)tapButtonFit2:(UIButton *)sender {
    CGSize size = [self.textFieldFit2.text sizeWithFont:[UIFont systemFontOfSize:13.0]
                         constrainedToSize:CGSizeMake(244, MAXFLOAT)
                             lineBreakMode:NSLineBreakByWordWrapping];
    [self.textFieldFit2.text boundingRectWithSize:CGSizeMake(244, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:<#(nullable NSDictionary<NSAttributedStringKey,id> *)#> context:<#(nullable NSStringDrawingContext *)#>]
    self.labelFit2.frame = CGRectMake(self.labelFit2.frame.origin.x, self.labelFit2.frame.origin.y, size.width, size.height);
    printf("tapButtonFit2 - height = %f, %f\n", self.labelFit2.frame.size.width, self.labelFit2.frame.size.height);
}

@end
