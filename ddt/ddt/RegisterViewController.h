//
//  RegisterViewController.h
//  ddt
//
//  Created by allen on 15/10/16.
//  Copyright (c) 2015年 Light. All rights reserved.
//

#import "MyBaseTableViewController.h"

@interface RegisterViewController : MyBaseTableViewController
@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UITextField *mailField;
- (IBAction)registerBtnClick:(id)sender;
- (IBAction)registerProtocol:(id)sender;
- (IBAction)verifyNumBtnClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *verifyBtn;

@end
