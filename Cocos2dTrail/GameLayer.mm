//
//  GameLayer.m
//  Cocos2dTrail
//
//  Created by Greg Wang on 4/22/13.
//  Copyright (c) 2013 Greg Wang. All rights reserved.
//

#import "GameLayer.h"

@implementation GameLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];

	// 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];

	// add layer as a child to scene
	[scene addChild: layer];

	// return the scene
	return scene;
}

- (id) init
{
    if ((self = [super initWithColor:ccc4(255,255,255,255)])) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        CCSprite *player = [CCSprite spriteWithFile:@"Icon.png"];
        player.position = ccp(player.contentSize.width/2, winSize.height/2);
        [self addChild:player];

		[self schedule:@selector(addMonster) interval:1.0];
		self.touchEnabled = TRUE;
    }
    return self;
}

- (void) addMonster {

    CCSprite * monster = [CCSprite spriteWithFile:@"Icon.png"];

    // Determine where to spawn the monster along the Y axis
    CGSize winSize = [CCDirector sharedDirector].winSize;
    int minY = monster.contentSize.height / 2;
    int maxY = winSize.height - monster.contentSize.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;

    // Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = ccp(winSize.width + monster.contentSize.width/2, actualY);
    [self addChild:monster];

    // Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;

    // Create the actions
    CCMoveTo * actionMove = [CCMoveTo actionWithDuration:actualDuration
												position:ccp(-monster.contentSize.width/2, actualY)];
    CCCallBlockN * actionMoveDone = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [node removeFromParentAndCleanup:YES];
    }];
    [monster runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
	
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [self convertTouchToNodeSpace:touch];

    // Set up initial location of projectile
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CCSprite *projectile = [CCSprite spriteWithFile:@"blocks.png"];
    projectile.position = ccp(20, winSize.height/2);

    // Determine offset of location to projectile
    CGPoint offset = ccpSub(location, projectile.position);

    // Bail out if you are shooting down or backwards
    if (offset.x <= 0) return;

    // Ok to add now - we've double checked position
    [self addChild:projectile];

    int realX = winSize.width + (projectile.contentSize.width/2);
    float ratio = (float) offset.y / (float) offset.x;
    int realY = (realX * ratio) + projectile.position.y;
    CGPoint realDest = ccp(realX, realY);

    // Determine the length of how far you're shooting
    int offRealX = realX - projectile.position.x;
    int offRealY = realY - projectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;

    // Move projectile to actual endpoint
    [projectile runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [node removeFromParentAndCleanup:YES];
	 }],
      nil]];

}

@end
