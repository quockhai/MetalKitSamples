//
//  ViewController.m
//  ParticleLab
//
//  Created by quockhai on 2019/2/21.
//  Copyright © 2019 Polymath. All rights reserved.
//

#import "ViewController.h"
#import "ParticleLab-Swift.h"
#import "PMSize.h"

enum ParticleCount {
    QtrMillion = 65536,
    HalfMillion = 131072,
    OneMillion =  262144,
    TwoMillion =  524288,
    FourMillion = 1048576,
    EightMillion = 2097152,
    SixteenMillion = 4194304
};

typedef NS_ENUM(NSInteger, ParticleMode) {
    kCloudChamber = 0,
    kOrbits = 1,
    kRespawn = 2,
    kMultiTouch = 3,
    kiPad = 4
};

@interface ViewController () <ParticleLabDelegate>
{
    CGFloat gravityWellAngle;
    ParticleMode particleMode;
}
@property(strong, nonatomic) ParticleLab * particleView;
@property(strong, nonatomic) UIButton * modeButton;

@property(strong, nonatomic) NSMutableArray * currentTouches;
@end

@implementation ViewController
@synthesize particleView;

-(void)loadView {
    [super loadView];
    
    CGFloat top = [PMSize sharedInstance].top;
    CGFloat bottom = PMSize.sharedInstance.bottom;
    
    CGFloat viewHeight = 50.0;
    CGFloat space = 10.0;
    
    ParticleLab * particleView = [[ParticleLab alloc] initWithWidth:[[PMSize sharedInstance] screenWidth] height:[[PMSize sharedInstance] screenHeight] - top - bottom numParticles:65536 hiDPI: false];
    particleView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:particleView];
    
    UIButton * modeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    modeButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:modeButton];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [particleView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:1.0],
                                              [particleView.heightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.heightAnchor multiplier:1.0],
                                              [particleView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [particleView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]
                                              ]];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [modeButton.widthAnchor constraintEqualToAnchor:modeButton.heightAnchor multiplier:1.0],
                                              [modeButton.heightAnchor constraintEqualToConstant:viewHeight],
                                              [modeButton.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor constant:-space],
                                              [modeButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-space]
                                              ]];
    
    self.particleView = particleView;
    self.modeButton = modeButton;
}

-(void)configureSubViews {
    self.particleView.particleLabDelegate = self;
    
    
    self.particleView.dragFactor = 0.5;
    self.particleView.respawnOutOfBoundsParticles = false;
    self.particleView.clearOnStep = true;
    [self.particleView resetParticlesWithEdgesOnly:true];
    

    self.modeButton.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.75];
    self.modeButton.layer.cornerRadius = 25.0;
    self.modeButton.layer.masksToBounds = true;
    [self.modeButton addTarget:self action:@selector(showModeSelection:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    
    self.currentTouches = [NSMutableArray new];
    
    particleMode = kOrbits;
    
    gravityWellAngle = 0.0;
    
    [self configureSubViews];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (particleMode != kRespawn) {
        [self setupParticleViewWithMode:particleMode];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)showModeSelection:(UIButton*)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Particle mode" message:@"Select a particle mode" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * cloudChamberAction = [UIAlertAction actionWithTitle:@"Cloud Chamber" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupParticleViewWithMode:kCloudChamber];
    }];
    [alertController addAction:cloudChamberAction];
    
    UIAlertAction * orbitsAction = [UIAlertAction actionWithTitle:@"Orbits" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupParticleViewWithMode:kOrbits];
    }];
    [alertController addAction:orbitsAction];
    
//    UIAlertAction * respawnAction = [UIAlertAction actionWithTitle:@"Respawn" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self setupParticleViewWithMode:kRespawn];
//    }];
//    [alertController addAction:respawnAction];
    
    UIAlertAction * blossomAction = [UIAlertAction actionWithTitle:@"Blossom" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupParticleViewWithMode:kiPad];
    }];
    [alertController addAction:blossomAction];
    
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:true completion:^{
            self.particleView.paused = false;
        }];
    }];
    [alertController addAction:cancelAction];
    
    
    if (alertController.popoverPresentationController != nil) {
        CGFloat x = sender.frame.origin.x;
        CGFloat y = sender.frame.origin.y;
        
        alertController.popoverPresentationController.sourceRect = CGRectMake(x, y, sender.frame.size.width, sender.frame.size.height);
        alertController.popoverPresentationController.sourceView = self.view;
    }
    
    self.particleView.paused = true;
    
    [self presentViewController:alertController animated:true completion:^{
        self.particleView.paused = false;
    }];
}

-(void)setupParticleViewWithMode:(ParticleMode)mode {
    switch (mode) {
        case kCloudChamber: {
            self.particleView.dragFactor = 0.8;
            self.particleView.respawnOutOfBoundsParticles = false;
            self.particleView.clearOnStep = true;
            [self.particleView resetParticlesWithEdgesOnly:true];
        } break;
        
        case kOrbits: {
            self.particleView.dragFactor = 0.82;
            self.particleView.respawnOutOfBoundsParticles = true;
            self.particleView.clearOnStep = true;
            [self.particleView resetParticlesWithEdgesOnly:false];
        } break;
        
        case kRespawn: {
            self.particleView.dragFactor = 0.98;
            self.particleView.respawnOutOfBoundsParticles = true;
            self.particleView.clearOnStep = true;
            [self.particleView resetParticlesWithEdgesOnly:true];
        } break;
        
        case kMultiTouch: {
            self.particleView.dragFactor = 0.95;
            self.particleView.respawnOutOfBoundsParticles = false;
            self.particleView.clearOnStep = true;
            [self.particleView resetParticlesWithEdgesOnly:false];
        } break;
        
        case kiPad: {
            self.particleView.dragFactor = 0.5;
            self.particleView.respawnOutOfBoundsParticles = true;
            self.particleView.clearOnStep = false;
            [self.particleView resetParticlesWithEdgesOnly:true];
        } break;
        
        default:
        break;
    }
}



-(void)particleLabDidUpdateWithStatus:(NSString *)status {
    
    [self.particleView resetGravityWells];
    
    switch (particleMode) {
        case kCloudChamber: {
            [self cloudChamberStep];
        } break;
        
        case kRespawn: {
            [self respawnStep];
        } break;
        
        case kOrbits: {
            [self orbitsStep];
        } break;
        
        case kiPad: {
            [self iPadStep];
        } break;
        
        case kMultiTouch: {
            [self multiTouchStep];
        } break;
        
        default:
        break;
    }
}

-(void)particleLabMetalUnavailable {
    
}

-(void)cloudChamberStep {
    gravityWellAngle = gravityWellAngle + 0.02;
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1
                                           normalisedPositionX:0.5 + 0.1 * sin(gravityWellAngle + M_PI * 0.5)
                                           normalisedPositionY:0.5 + 0.1 * cos(gravityWellAngle + M_PI * 0.5)
                                                          mass:11 * sin(gravityWellAngle / 1.9)
                                                          spin:23 * cos(gravityWellAngle / 2.1)];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:4
                                           normalisedPositionX:0.5 + 0.1 * sin(gravityWellAngle + M_PI * 1.5)
                                           normalisedPositionY:0.5 + 0.1 * cos(gravityWellAngle + M_PI * 1.5)
                                                          mass:11 * sin(gravityWellAngle / 1.9)
                                                          spin:23 * cos(gravityWellAngle / 2.1)];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:2
                                           normalisedPositionX:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * cos(gravityWellAngle / 1.3)
                                           normalisedPositionY:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * sin(gravityWellAngle / 1.3)
                                                          mass:26
                                                          spin:-19 * sin(gravityWellAngle * 1.5)];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:3
                                           normalisedPositionX:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * cos(gravityWellAngle / 1.3 + M_PI)
                                           normalisedPositionY:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * sin(gravityWellAngle / 1.3 + M_PI)
                                                          mass:26
                                                          spin:-19 * sin(gravityWellAngle * 1.5)];
}

-(void)iPadStep {
    gravityWellAngle = gravityWellAngle + 0.004;
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1
                                           normalisedPositionX:0.5 + 0.1 * sin(gravityWellAngle + M_PI * 0.5)
                                           normalisedPositionY:0.5 + 0.1 * cos(gravityWellAngle + M_PI * 0.5)
                                                          mass:11 * sin(gravityWellAngle / 1.8)
                                                          spin:23 * cos(gravityWellAngle / 2.1)];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:2
                                           normalisedPositionX:0.5 + 0.1 * sin(gravityWellAngle + M_PI * 1.5)
                                           normalisedPositionY:0.5 + 0.1 * cos(gravityWellAngle + M_PI * 1.5)
                                                          mass:11 * sin(gravityWellAngle / 0.9)
                                                          spin:23 * cos(gravityWellAngle / 1.05)];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:3
                                           normalisedPositionX:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * cos(gravityWellAngle / 1.3)
                                           normalisedPositionY:0.5 + (0.35 + sin(gravityWellAngle * 2.7)) * sin(gravityWellAngle / 1.3)
                                                          mass:13
                                                          spin:19 * sin(gravityWellAngle * 1.75)];
    
    CGPoint particleOnePosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:1];
    CGPoint particleTwoPosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:2];
    CGPoint particleThreePosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:3];
    
    
    [self.particleView setGravityWellPropertiesWithGravityWell:4
                                           normalisedPositionX:(particleOnePosition.x + particleTwoPosition.x + particleThreePosition.x) / 3 + 0.03 * sin(gravityWellAngle)
                                           normalisedPositionY:(particleOnePosition.y + particleTwoPosition.y + particleThreePosition.y) / 3 + 0.03 * cos(gravityWellAngle)
                                                          mass:8
                                                          spin:25 * sin(gravityWellAngle / 3 )];
}

-(void)orbitsStep {
    gravityWellAngle = gravityWellAngle + 0.0015;
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1
                                           normalisedPositionX:0.5 + 0.006 * cos(gravityWellAngle * 43)
                                           normalisedPositionY:0.5 + 0.006 * sin(gravityWellAngle * 43)
                                                          mass:10
                                                          spin:24];
    
    CGPoint particleOnePosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:1];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:2
                                           normalisedPositionX:particleOnePosition.x + 0.3 * sin(gravityWellAngle * 5)
                                           normalisedPositionY:particleOnePosition.y + 0.3 * cos(gravityWellAngle * 5)
                                                          mass:4
                                                          spin:18];
    
    CGPoint particleTwoPosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:2];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:3
                                           normalisedPositionX:particleTwoPosition.x + 0.1 * cos(gravityWellAngle * 23)
                                           normalisedPositionY:particleTwoPosition.y + 0.1 * sin(gravityWellAngle * 23)
                                                          mass:6
                                                          spin:17];
    
    CGPoint particleThreePosition = [self.particleView getGravityWellNormalisedPositionWithGravityWell:3];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:4
                                           normalisedPositionX:particleThreePosition.x + 0.03 * sin(gravityWellAngle * 37)
                                           normalisedPositionY:particleThreePosition.y + 0.03 * cos(gravityWellAngle * 37)
                                                          mass:8
                                                          spin:25];
}

-(void)respawnStep {
    gravityWellAngle = gravityWellAngle + 0.02;
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1 normalisedPositionX:0.5 + 0.45 * sin(gravityWellAngle) normalisedPositionY:0.5 + 0.15 * cos(gravityWellAngle) mass:14 spin:16];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1 normalisedPositionX:0.5 + 0.25 * cos(gravityWellAngle * 1.3) normalisedPositionY:0.5 + 0.6 * sin(gravityWellAngle * 1.3) mass:8 spin:10];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.currentTouches addObjectsFromArray:[touches allObjects]];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.currentTouches removeObjectsInArray:[touches allObjects]];
}


-(void)multiTouchStep {
    for (int index=0; index < self.currentTouches.count; index++) {
        if (index < 4) {
            UITouch * currentTouch = [self.currentTouches objectAtIndex:index];
            
            CGFloat touchMultiplier = 1;
            if (!(currentTouch.force == 0 && currentTouch.maximumPossibleForce == 0)) {
                touchMultiplier = currentTouch.force / currentTouch.maximumPossibleForce;
            }
            
            NSLog(@"Touch: %.2f", touchMultiplier);
            [self.particleView setGravityWellPropertiesWithGravityWell:index
                                                   normalisedPositionX:[currentTouch locationInView:self.view].x / self.view.frame.size.width
                                                   normalisedPositionY:[currentTouch locationInView:self.view].y / self.view.frame.size.height
                                                                  mass:40 * touchMultiplier
                                                                  spin:20 * touchMultiplier];
        }
    }
    
    for (int index=0; index<self.currentTouches.count; index++) {
        if (index < 4) {
            [self.particleView setGravityWellPropertiesWithGravityWell:index
                                                   normalisedPositionX:0.5
                                                   normalisedPositionY:0.5
                                                                  mass:0.0
                                                                  spin:0.0];
        }
    }
 
}


@end
