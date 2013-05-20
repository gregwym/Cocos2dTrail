//
//  Box2dLayer.m
//  Cocos2dTrail
//
//  Created by Greg Wang on 5/18/13.
//  Copyright (c) 2013 Greg Wang. All rights reserved.
//

#import "Box2dLayer.h"

@interface Box2dLayer()

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;
@property (strong) CCSprite *player;
@property (strong) CCTMXLayer *meta;

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

// Helper: Position to Tile Coord (upper left, increments each tile)
- (CGPoint)tileCoordForPosition:(CGPoint)position
{
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return CGPointMake(x, y);
}

- (CGPoint)positionForTileCoord:(CGPoint)coord
{
    int x = coord.x;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - coord.y);
    return CGPointMake(x, y);
}

- (void)addPolygon:(NSString *)polyCoords toBody:(b2Body *)body
{
	NSArray *vertices = [polyCoords componentsSeparatedByString:@" "];

	b2PolygonShape groundPolygon;
	b2FixtureDef groundFixtureDef;
	groundFixtureDef.shape = &groundPolygon;
	int numOfVertex = [vertices count];

	b2Vec2 *polyVertices = new b2Vec2[numOfVertex];
	int i = 0;

	for (NSString *vertex in vertices) {
		NSArray *xy = [vertex componentsSeparatedByString:@","];
		CGFloat x = [[xy objectAtIndex:0] floatValue];
		CGFloat y = [[xy objectAtIndex:1] floatValue];
		// NSLog(@"Offset: %f, %f", x, y);

		polyVertices[i].x = x/PTM_RATIO;
		polyVertices[i].y = (0.0f - y)/PTM_RATIO;
		// NSLog(@"Coord: %f, %f", polyVertices[i].x, polyVertices[i].y);
		i++;
	}
	groundPolygon.Set(polyVertices, numOfVertex);
	delete [] polyVertices;

	body->CreateFixture(&groundFixtureDef);
}

- (void)addPolyline:(NSString *)polyCoords toBody:(b2Body *)body
{
	NSArray *vertices = [polyCoords componentsSeparatedByString:@" "];

	b2EdgeShape groundEdge;
	b2FixtureDef groundFixtureDef;
	groundFixtureDef.shape = &groundEdge;
	int numOfVertex = [vertices count];

	b2Vec2 *polyVertices = new b2Vec2[numOfVertex];
	int i = 0;

	for (NSString *vertex in vertices) {
		NSArray *xy = [vertex componentsSeparatedByString:@","];
		CGFloat x = [[xy objectAtIndex:0] floatValue];
		CGFloat y = [[xy objectAtIndex:1] floatValue];
		// NSLog(@"Offset: %f, %f", x, y);

		polyVertices[i].x = x/PTM_RATIO;
		polyVertices[i].y = (0.0f - y)/PTM_RATIO;
		// NSLog(@"Coord: %f, %f", polyVertices[i].x, polyVertices[i].y);
		i++;
	}
	groundEdge.Set(polyVertices[0], polyVertices[1]);
	delete [] polyVertices;

	body->CreateFixture(&groundFixtureDef);
}

- (id)init
{
	if ((self = [super init])) {
		CGSize winSize = [CCDirector sharedDirector].winSize;

		self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"Map.tmx"];
        self.background = [self.tileMap layerNamed:@"Background"];

		self.meta = [self.tileMap layerNamed:@"Meta"];
		self.meta.visible = NO;
		[self addChild:self.tileMap z:-1];

		// Create sprite and add it to the layer
		_player = [CCSprite spriteWithFile:@"Player.png" rect:CGRectMake(0, 0, 52, 52)];
		_player.position = ccp(480, 300);
		[self addChild:_player];

		// Create a world
		b2Vec2 gravity = b2Vec2(0.0f, -9.8f);
		_world = new b2World(gravity);

		_debugDraw = new GLESDebugDraw(PTM_RATIO);
        _world->SetDebugDraw(_debugDraw);
		uint32 flags =0;
        flags += b2Draw::e_shapeBit;
//		flags += b2Draw::e_jointBit;
//		flags += b2Draw::e_aabbBit;
//		flags += b2Draw::e_pairBit;
//		flags += b2Draw::e_centerOfMassBit;
        _debugDraw->SetFlags(flags);

		// Create player body and shape
		b2BodyDef playerBodyDef;
		playerBodyDef.type = b2_dynamicBody;
		playerBodyDef.position.Set(480/PTM_RATIO, 300/PTM_RATIO);
		playerBodyDef.userData = (__bridge void *)_player;
		playerBodyDef.linearDamping = 0.1f;
		_body = _world->CreateBody(&playerBodyDef);

		b2CircleShape circle;
		circle.m_radius = 26.0/PTM_RATIO;

		b2FixtureDef playerShapeDef;
		playerShapeDef.shape = &circle;
		playerShapeDef.density = 1.0f;
		playerShapeDef.friction = 0.2f;
		playerShapeDef.restitution = 0.8f;
		_body->CreateFixture(&playerShapeDef);

		// Create edges according to the tile map
		CCTMXObjectGroup *bodyObjects = [self.tileMap objectGroupNamed:@"BodyDef"];
		CGFloat x, y;
		for (NSDictionary *objPoint in [bodyObjects objects]) {
			// Calculate ground body origin point
			x = [[objPoint valueForKey:@"x"] floatValue];
			y = [[objPoint valueForKey:@"y"] floatValue];
			CGPoint position = CGPointMake(x, y);
			NSLog(@"Poly origin at %f, %f", position.x, position.y);

			// Create ground body def
			b2BodyDef groundBodyDef;
			groundBodyDef.position.Set(position.x/PTM_RATIO, position.y/PTM_RATIO);
			b2Body *groundBody = _world->CreateBody(&groundBodyDef);

			// Draw edges according to the polygon/polyline
			NSString *verticesString = [objPoint valueForKey:@"polygonPoints"];
			if (verticesString == NULL) {
				verticesString = [objPoint valueForKey:@"polylinePoints"];
				[self addPolyline:verticesString toBody:groundBody];
			} else {
				[self addPolygon:verticesString toBody:groundBody];
			}
		}
		
		[self schedule:@selector(tick:) interval:0.02f];
	}
	return self;
}

-(void) draw{
	[super draw];

	_world->DrawDebugData();
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

- (void)tick:(ccTime) dt {

    _world->Step(dt, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() != NULL) {
            CCSprite *ballData = (__bridge CCSprite *)b->GetUserData();
			CGPoint position = CGPointMake(b->GetPosition().x * PTM_RATIO,
										   b->GetPosition().y * PTM_RATIO);
            ballData.position = position;
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
			[self setViewPointCenter:position];
        }
    }

}

@end
