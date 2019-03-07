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

@interface ViewController () <ParticleLabDelegate>
{
    CGFloat gravityWellAngle;
}
@property(strong, nonatomic) ParticleLab * particleView;
@end

@implementation ViewController
@synthesize particleView;

-(void)loadView {
    [super loadView];
    
    CGFloat top = [PMSize sharedInstance].top;
    CGFloat bottom = PMSize.sharedInstance.bottom;
    
    ParticleLab * particleView = [[ParticleLab alloc] initWithWidth:[[PMSize sharedInstance] screenWidth] height:[[PMSize sharedInstance] screenHeight] - top - bottom numParticles:65536 hiDPI: false];
    particleView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:particleView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [particleView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:1.0],
                                              [particleView.heightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.heightAnchor multiplier:1.0],
                                              [particleView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [particleView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]
                                              ]];
    
    self.particleView = particleView;
}

-(void)configureSubViews {
    
    self.particleView.particleLabDelegate = self;
    
    
    // Respawn
//    self.particleView.dragFactor = 0.98;
//    self.particleView.respawnOutOfBoundsParticles = true;
//    self.particleView.clearOnStep = true;
//    [self.particleView resetParticlesWithEdgesOnly:true];
    
    // CloudChamber
//    self.particleView.dragFactor = 0.8;
//    self.particleView.respawnOutOfBoundsParticles = false;
//    self.particleView.clearOnStep = true;
//    [self.particleView resetParticlesWithEdgesOnly:true];
    
    self.particleView.dragFactor = 0.5;
    self.particleView.respawnOutOfBoundsParticles = false;
    self.particleView.clearOnStep = true;
    [self.particleView resetParticlesWithEdgesOnly:true];
    
//    self.particleView.backgroundColor = UIColor.orangeColor;
//    [self.view addSubview:self.particleView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    
    
    gravityWellAngle = 0.0;
    
    [self configureSubViews];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)particleLabDidUpdateWithStatus:(NSString *)status {
//    NSLog(@"Status: %@", status);
//    [self respawnStep];
    
    [self cloudChamberStep];
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

-(void)respawnStep {
    gravityWellAngle = gravityWellAngle + 0.02;
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1 normalisedPositionX:0.5 + 0.45 * sin(gravityWellAngle) normalisedPositionY:0.5 + 0.15 * cos(gravityWellAngle) mass:14 spin:16];
    
    [self.particleView setGravityWellPropertiesWithGravityWell:1 normalisedPositionX:0.5 + 0.25 * cos(gravityWellAngle * 1.3) normalisedPositionY:0.5 + 0.6 * sin(gravityWellAngle * 1.3) mass:8 spin:10];
}

//-(void)orbitsStep {
//    gravityWellAngle = gravityWellAngle + 0.0015;
//
//    [self.particleView setGravityWellPropertiesWithGravityWell:1
//                                           normalisedPositionX:0.5 + 0.006 * cos(gravityWellAngle * 43)
//                                           normalisedPositionY:0.5 + 0.006 * sin(gravityWellAngle * 43)
//                                                          mass:10
//                                                          spin:24];
//
//
////    let particleOnePosition = particleView.getGravityWellNormalisedPosition(gravityWell: .One)
//
//    particleLab.setGravityWellProperties(gravityWell: .Two,
//                                         normalisedPositionX: particleOnePosition.x + 0.3 * sin(gravityWellAngle * 5),
//                                         normalisedPositionY: particleOnePosition.y + 0.3 * cos(gravityWellAngle * 5),
//                                         mass: 4,
//                                         spin: 18)
//
//    let particleTwoPosition = particleLab.getGravityWellNormalisedPosition(gravityWell: .Two)
//
//    particleLab.setGravityWellProperties(gravityWell: .Three,
//                                         normalisedPositionX: particleTwoPosition.x + 0.1 * cos(gravityWellAngle * 23),
//                                         normalisedPositionY: particleTwoPosition.y + 0.1 * sin(gravityWellAngle * 23),
//                                         mass: 6,
//                                         spin: 17)
//
//    let particleThreePosition = particleLab.getGravityWellNormalisedPosition(gravityWell: .Three)
//
//    particleLab.setGravityWellProperties(gravityWell: .Four,
//                                         normalisedPositionX: particleThreePosition.x + 0.03 * sin(gravityWellAngle * 37),
//                                         normalisedPositionY: particleThreePosition.y + 0.03 * cos(gravityWellAngle * 37),
//                                         mass: 8,
//                                         spin: 25)
//}

@end
