//
//  Box2dLayer.h
//  Cocos2dTrail
//
//  Created by Greg Wang on 5/18/13.
//  Copyright (c) 2013 Greg Wang. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"


#define PTM_RATIO 32.0

@interface Box2dLayer : CCLayerColor {
	b2World *_world;
	b2Body *_body;
	CCSprite *_player;
	GLESDebugDraw *_debugDraw;
}

+ (id) scene;

@end
