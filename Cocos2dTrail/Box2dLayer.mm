//
//  Box2dLayer.m
//  Cocos2dTrail
//
//  Created by Greg Wang on 5/18/13.
//  Copyright (c) 2013 Greg Wang. All rights reserved.
//

#import "Box2dLayer.h"

@interface Box2dLayer()

@end

@implementation Box2dLayer

+ (CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];

	// 'layer' is an autorelease object.
	Box2dLayer *layer = [Box2dLayer node];

	// add layer as a child to scene
	[scene addChild: layer];

	// return the scene
	return scene;
}

- (id)init {
	if ((self = [super init])) {
		CGSize winSize = [CCDirector sharedDirector].winSize;

		// Create sprite and add it to the layer
		_ball = [CCSprite spriteWithFile:@"Player.png" rect:CGRectMake(0, 0, 52, 52)];
		_ball.position = ccp(100, 300);
		[self addChild:_ball];

		// Create a world
		b2Vec2 gravity = b2Vec2(0.0f, -8.0f);
		_world = new b2World(gravity);

		// Create ball body and shape
		b2BodyDef ballBodyDef;
		ballBodyDef.type = b2_dynamicBody;
		ballBodyDef.position.Set(100/PTM_RATIO, 300/PTM_RATIO);
		ballBodyDef.userData = (__bridge void *)_ball;
		_body = _world->CreateBody(&ballBodyDef);

		b2CircleShape circle;
		circle.m_radius = 26.0/PTM_RATIO;

		b2FixtureDef ballShapeDef;
		ballShapeDef.shape = &circle;
		ballShapeDef.density = 1.0f;
		ballShapeDef.friction = 0.2f;
		ballShapeDef.restitution = 0.8f;
		_body->CreateFixture(&ballShapeDef);

		// Create edges around the entire screen
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0,0);

		b2Body *groundBody = _world->CreateBody(&groundBodyDef);
		b2EdgeShape groundEdge;
		b2FixtureDef boxShapeDef;
		boxShapeDef.shape = &groundEdge;

		//wall definitions
		groundEdge.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0));
		groundBody->CreateFixture(&boxShapeDef);
		
		[self schedule:@selector(tick:) interval:0.02f];
	}
	return self;
}

- (void)tick:(ccTime) dt {

    _world->Step(dt, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() != NULL) {
            CCSprite *ballData = (__bridge CCSprite *)b->GetUserData();
            ballData.position = ccp(b->GetPosition().x * PTM_RATIO,
                                    b->GetPosition().y * PTM_RATIO);
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
    }

}

@end
