//
//  LoginViewController.m
//  ddt
//
//  Created by allen on 15/10/14.
//  Copyright (c) 2015年 Light. All rights reserved.
//
#import "LoginViewController.h"
#define InputViewHeight 60.0
#define UserIconWidth 10
#import "FindBackPasswordViewController.h"
#import "RegisterViewController.h"
#import "NSString+MD5Addition.h"
@interface LoginViewController ()<UITextFieldDelegate,QCheckBoxDelegate>

@end

@implementation LoginViewController
@synthesize phoneNumTextField;
@synthesize passwordTextField;
@synthesize remeberPasswordandPhone;
@synthesize autoLoginNextime;
@synthesize loginBtn;
@synthesize regesterBtn;
@synthesize findPasswordBtn;
@synthesize mainView;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = @"登录";
    [self createLeftBarItemWithBackTitle];
    mainView.layer.borderColor = [RGBA(207, 207, 207, 1)CGColor];
    mainView.layer.borderWidth = 1;
    remeberPasswordandPhone.checked = YES;
    autoLoginNextime.checked = YES;
    remeberPasswordandPhone.delegate = self;
    autoLoginNextime.delegate = self;
    [self initViews];
    //注册键盘收起的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    // Do any additional setup after loading the view.
}
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    [UIView animateWithDuration:1.0 animations:^{
        for (UIView *sview in self.view.subviews)
        {
            sview.transform=CGAffineTransformMakeTranslation(0, -46);
        }
    } completion:^(BOOL finished) {
    }];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [UIView animateWithDuration:1.0 animations:^{
        for (UIView *sview in self.view.subviews)
        {
            sview.transform=CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {
    }];
}
-(void)goback:(UIButton *)btn{
   // [self dismissViewControllerAnimated:YES completion:nil];
    if ([MySharetools shared].isFromMycenter) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [MySharetools shared].isFirstSignupViewController = YES;
        }];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-(void)initViews{
    phoneNumTextField.keyboardType = UIKeyboardTypeNumberPad;
    phoneNumTextField.font = [UIFont systemFontOfSize:14];
    [phoneNumTextField setReturnKeyType:UIReturnKeyNext];
    phoneNumTextField.delegate = self;
    passwordTextField.secureTextEntry = YES;
    passwordTextField.font = [UIFont systemFontOfSize:14];
    if ([[MySharetools shared]isRemeberPasswordandPhone]) {
        phoneNumTextField.text = [[MySharetools shared]getPhoneNumber];
        passwordTextField.text = [[MySharetools shared]getPassWord];
    }
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if ([phoneNumTextField isFirstResponder]) {
        [phoneNumTextField resignFirstResponder];
        [passwordTextField becomeFirstResponder];
    }
    return YES;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if ([phoneNumTextField isFirstResponder]) {
        [phoneNumTextField resignFirstResponder];
    }
    if ([passwordTextField isFirstResponder]) {
        [passwordTextField resignFirstResponder];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)loginBtnClick:(id)sender {
    //    jsondata={"mobile":"15136216190","pwd":"111","token":"15136216190(!)*^*1446701200"//18016373660,123456789www wyg
    NSDate *localDate = [NSDate date]; //获取当前时间
    NSString *timeString = [NSString stringWithFormat:@"%lld", (long long)[localDate timeIntervalSince1970]];  //转化为UNIX时间戳
    NSString *token = [NSString stringWithFormat:@"%@(!)*^*%@",phoneNumTextField.text,timeString];
    //...test
    NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:phoneNumTextField.text,@"mobile", [passwordTextField.text stringFromMD5],@"pwd",token,@"token",nil];
    NSString *jsonStr = [NSString jsonStringFromDictionary:dic1];
    
    NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:jsonStr,@"jsondata", nil];
    [SVProgressHUD showWithStatus:@"正在登录"];
    RequestTaskHandle *_task = [RequestTaskHandle taskWithUrl:NSLocalizedString(@"url_login", @"") parms:dic2 andSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"...responseObject  :%@",responseObject);
        
        if ([[responseObject objectForKey:@"result"]integerValue] == 0) {
            [SVProgressHUD showSuccessWithStatus:@"登录成功"];
            
            NSDictionary *dict = [responseObject objectForKey:@"data"];
            if ([dict isKindOfClass:[NSDictionary class]]&&dict) {
                [[NSUserDefaults standardUserDefaults]setObject:dict forKey:@"loginSuccessInfo"];
                NSString *sessionid = [dict objectForKey:@"sessionid"];
                if (sessionid!=nil) {
                    [[NSUserDefaults standardUserDefaults]setObject:sessionid forKey:@"sessionid"];
                }
                NSString *nickName = [dict objectForKey:@"xm"];
                if (nickName) {
                    [[NSUserDefaults standardUserDefaults]setObject:nickName forKey:@"nickName"];
                }
                [[NSUserDefaults standardUserDefaults]synchronize];
            }
            if (remeberPasswordandPhone.checked) {
                [[NSUserDefaults standardUserDefaults]setObject:phoneNumTextField.text forKey:@"rememberPhone"];
                [[NSUserDefaults standardUserDefaults]setObject:passwordTextField.text forKey:@"remeberPassword"];
                [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"isRemeberPasswordandPhone"];
            }else{
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"remeberPassword"];
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"rememberPhone"];
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"isRemeberPasswordandPhone"];
            }
            
            if (autoLoginNextime.checked) {
                [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"isAutoLogin"];
            }else{
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"isAutoLogin"];
            }
            [[NSUserDefaults standardUserDefaults]synchronize];
            [MySharetools shared].isFirstLoginSuccess = YES;
            
            if ([MySharetools shared].isFromMycenter) {
                [MySharetools shared].isFirstSignupViewController = NO;
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    //[MySharetools shared].isFirstSignupViewController = YES;
                }];
            }else{
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        else
        {
            //[MySharetools shared].isFirstSignupViewController = YES;
            [SVProgressHUD showInfoWithStatus:[responseObject objectForKey:@"message"]];
        }
    } faileBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showInfoWithStatus:@"请求服务器失败,请重试"];
    }];
    
    [HttpRequestManager doPostOperationWithTask:_task];
}

- (IBAction)registerBtnClick:(id)sender {
    RegisterViewController *registerVC = [[MySharetools shared]getViewControllerWithIdentifier:@"registerView" andstoryboardName:@"me"];
    [self.navigationController pushViewController:registerVC animated:YES];
}

- (IBAction)findBackBtnClick:(id)sender {
    FindBackPasswordViewController *find = [[FindBackPasswordViewController alloc]init];
    [self.navigationController pushViewController:find animated:YES];
}
- (void)didSelectedCheckBox:(QCheckBox *)checkbox checked:(BOOL)checked{
    if (checkbox == remeberPasswordandPhone) {
        if (remeberPasswordandPhone.checked == NO) {
            remeberPasswordandPhone.checked =remeberPasswordandPhone.checked;
            autoLoginNextime.checked = NO;
        }else{
            remeberPasswordandPhone.checked =remeberPasswordandPhone.checked;
            autoLoginNextime.checked = autoLoginNextime.checked;
        }
    }else{
        if (autoLoginNextime.checked) {
            remeberPasswordandPhone.checked = YES;
            autoLoginNextime.checked = autoLoginNextime.checked;
        }else{
            remeberPasswordandPhone.checked =remeberPasswordandPhone.checked;
            autoLoginNextime.checked = autoLoginNextime.checked;
        }
    }
}
@end
