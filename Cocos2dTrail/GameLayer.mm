//
//  GameLayer.m
//  Cocos2dTrail
//
//  Created by Greg Wang on 4/22/13.
//  Copyright (c) 2013 Greg Wang. All rights reserved.
//

#import "GameLayer.h"

@interface GameLayer ()

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCSprite *player;
@property (strong) CCTMXLayer *meta;

@end

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

-(id) init
{
	if( (self=[super init]) ) {

        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        self.background = [self.tileMap layerNamed:@"Background"];

		self.meta = [self.tileMap layerNamed:@"Meta"];
		self.meta.visible = NO;

		CCTMXObjectGroup *objectGroup = [self.tileMap objectGroupNamed:@"Objects"];
		NSAssert(objectGroup != nil, @"tile map has no objects object layer");

		NSDictionary *spawnPoint = [objectGroup objectNamed:@"SpawnPoint"];
		float x = [spawnPoint[@"x"] floatValue] + [spawnPoint[@"width"] floatValue] / 2;
		float y = [spawnPoint[@"y"] floatValue] + [spawnPoint[@"height"] floatValue] / 2;


		self.player = [CCSprite spriteWithFile:@"Player.png"];
		self.player.position = ccp(x,y);

		[self addChild:self.player];
		[self setViewPointCenter:self.player.position];

		self.touchEnabled = YES;

		[self addChild:self.tileMap z:-1];
    }
    return self;
}

- (void)setViewPointCenter:(CGPoint) position {

    CGSize winSize = [CCDirector sharedDirector].winSize;

    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (self.tileMap.mapSize.width * self.tileMap.tileSize.width) - winSize.width / 2);
    y = MIN(y, (self.tileMap.mapSize.height * self.tileMap.tileSize.height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);

    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}

#pragma mark - handle touches
-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self
                                                              priority:0
                                                       swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void)setPlayerPosition:(CGPoint)position {
	CGPoint tileCoord = [self tileCoordForPosition:position];
	int tileGid = [_meta tileGIDAt:tileCoord];
	if (tileGid) {
		NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
		if (properties) {
			NSString *collision = properties[@"Collidable"];
			if (collision && [collision isEqualToString:@"Yes"]) {
				return;
			}
		}
	}
//	self.player.position = position;
	[self.player runAction:[CCMoveTo actionWithDuration:0.2f position:position]];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];

    CGPoint playerPos = self.player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);

    if ( abs(diff.x) > abs(diff.y) ) {
        if (diff.x > 0) {
            playerPos.x += self.tileMap.tileSize.width;
        } else {
            playerPos.x -= self.tileMap.tileSize.width;
        }
    } else {
        if (diff.y > 0) {
            playerPos.y += self.tileMap.tileSize.height;
        } else {
            playerPos.y -= self.tileMap.tileSize.height;
        }
    }

    CCLOG(@"playerPos %@",CGPointCreateDictionaryRepresentation(playerPos));

    // safety check on the bounds of the map
    if (playerPos.x <= (self.tileMap.mapSize.width * self.tileMap.tileSize.width) &&
        playerPos.y <= (self.tileMap.mapSize.height * self.tileMap.tileSize.height) &&
        playerPos.y >= 0 &&
        playerPos.x >= 0 )
    {
        [self setPlayerPosition:playerPos];
    }

    [self setViewPointCenter:playerPos];
}

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}

@end
