//
//  Gameplay.m
//  DoDaDishes
//
//  Created by Henna Olli on 11/11/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay
{
    CCNode* currentDish;
    CCNode* cleanDish;
    CCNode* leftHand;
    CCLabelTTF* scoreLabel;
    CCNode* sponge;
    CCNode* spongeHand;
    CCLabelTTF* dishFoundLabel;
    CCNode* water;
    CCLabelTTF *gameOverLabel;
    CCActionScaleTo* cleanDishEnter;
    CCActionScaleTo* dirtyDishEnter;
    int displayedScore;
    CCNode* center;
    int gameState;
    CCNode* spongeRestPos;
    CCNode* leftHandRestPos;
    CCActionFadeOut *fadeOut;
    CCActionFadeIn *handFadeIn;
    CCActionMoveTo* moveSponge;
    CCActionMoveTo* moveLeftHand;
    CCActionScaleTo* cleanDishZoomOut;
    CCActionTintTo* makeWaterRed;
    CCActionTintBy* tintHandRed;
    CCNode* dishHidingPoint;
    int hidingPointX;
    int hidingPointY;
}

- (void)didLoadFromCCB
{
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    // initializing the scoreLabel's attributes
    scoreLabel.string = @"Score: 0";
    scoreLabel.verticalAlignment = CCTextAlignmentCenter;

    /* gameStates are the following:
     0 = searching for dish
     1 = dish found
     2 = washing dish
     3 = putting dish away
     */
    gameState = 0;
    
    displayedScore = 0;
    
    // initializing actions
    cleanDishZoomOut = [CCActionScaleTo actionWithDuration:2 scale:0.1];
    fadeOut = [CCActionFadeOut actionWithDuration:1.5f];
    handFadeIn = [CCActionFadeIn actionWithDuration:1];
    makeWaterRed = [CCActionTintTo actionWithDuration:7 color:[CCColor redColor]];
    tintHandRed = [CCActionTintBy actionWithDuration:6 red:0 green:-0.6 blue:-0.6];
    
    // making sure objects are correctly z-ordered
    leftHand.zOrder = 2;
    sponge.zOrder = 3;
    scoreLabel.zOrder = 10;
    
    // hide the dish from the player
    dishHidingPoint.opacity = 0;
    
    // set the position of the first dish
    dishHidingPoint.position = [self makeHidingPoint];

}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    // getting location of touch
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (gameState)
    {
        case 0:
            if(CGRectContainsPoint([water boundingBox], touchLocation))
            {
                // if the hand is in the water, make it transparent
                leftHand.opacity = 0.4;
            }
            break;

        default:
            break;
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (gameState)
    {
        case 0:
            // if the hand is in the water, make it transparent
            if(CGRectContainsPoint([water boundingBox], touchLocation))
            {
                leftHand.opacity = 0.4;
            }
            else
                leftHand.opacity = 1;
            leftHand.position = touchLocation;
            
            // if the hand hits the dish, pick it up
            if(CGRectContainsPoint([dishHidingPoint boundingBox], touchLocation))
                [self findDish];
            break;
        case 1:
            leftHand.position = touchLocation;
            break;
        case 2:
            // do dish if the sponge is on it
            if(CGRectContainsPoint([currentDish boundingBox], touchLocation))
                [self doDish];
            sponge.position = touchLocation;
            break;
        case 3:
            if(CGRectContainsPoint([cleanDish boundingBox], touchLocation))
            {
                // if the dish is clean, move the dish and the hand
                cleanDish.position = touchLocation;
                leftHand.position = touchLocation;
                leftHand.zOrder = 3;
            }
            break;
        default:
            break;
    }
 
    
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // stop washing when the touch ends
    [self unschedule:@selector(washTick)];
    
    switch (gameState)
    {
        case 0:
            leftHand.opacity = 1;
            break;
        case 1:
            // if dish has been found, spawn it
            [self spawnDish];
            break;
        case 2:
            if(currentDish.opacity <= 0)
            {
                leftHand.zOrder = 5;
                // begin washing dish if the dirty dish is gone
                [self gameStateChanged:3];
            }
            break;
        case 3:
            if(!CGRectContainsPoint([water boundingBox], cleanDish.position))
            {
                // if the clean dish is moved outside the water, make it small and go back to searching for dish
                [self removeChild:currentDish];
                [cleanDish runAction:cleanDishZoomOut];
                [self gameStateChanged:0];
            }
            break;
        default:
            break;
    }

}

// this method displays a "dish found" message and changes gamestate to dish found
-(void)findDish
{
    dishFoundLabel = [CCLabelTTF labelWithString:@"Dish found!" fontName:@"Marker Felt" fontSize:32 ];
    dishFoundLabel.fontColor = [CCColor blackColor];
    dishFoundLabel.position = center.position;
    
    [self addChild:dishFoundLabel];
    [self gameStateChanged:1];
}


-(void)spawnDish
{
    // move left hand to center
    moveLeftHand = [CCActionMoveTo actionWithDuration:0.5f position:center.position];
    [leftHand runAction:moveLeftHand];
    [self removeChild:dishFoundLabel];
    
    // initialize the chance of a deadly knife, a random number between 0-20
    int knifeChance = arc4random_uniform(20);
    
    int dishNumber = arc4random()%4;
    
    NSString* dirtyDishName;
    NSString* cleanDishName;
    
    if(knifeChance == 10)
    {
        dishNumber = 4;
    }
    
    switch (dishNumber)
    {
        // based on the dishnumber, set the name of the dish
        case 0:
            dirtyDishName = @"DirtyPlate";
            cleanDishName = @"CleanPlate";
            break;
        case 1:
            dirtyDishName = @"DirtyFork";
            cleanDishName = @"CleanFork";
            break;
        case 2:
            dirtyDishName = @"DirtySpoon";
            cleanDishName = @"CleanSpoon";
            break;
        case 3:
            dirtyDishName = @"DirtyKnife";
            cleanDishName = @"CleanKnife";
            break;
        default: //if number is 4, it's game over
            dirtyDishName = @"DeadlyKnife";
            cleanDishName = @"DeadlyKnife";
            [self killPlayer];
            break;
    }
    
    // load the sprites
    currentDish = [CCBReader load:dirtyDishName];
    cleanDish = [CCBReader load:cleanDishName];
    
    // initialize the dish enter actions
    cleanDishEnter = [CCActionScaleTo actionWithDuration:1.5f scale:1];
    dirtyDishEnter = [CCActionScaleTo actionWithDuration:1.5f scale:1];
    
    // make the dishes initially invisible
    cleanDish.scale = 0;
    currentDish.scale = 0;
    
    // center the dishes
    currentDish.position =  center.position;
    cleanDish.position = center.position;
    
    [self addChild:cleanDish];
    [self addChild:currentDish];
    
    // place the sponge on top of the newly added dishes
    sponge.zOrder = 2;
    
    // scale in the dishes
    [cleanDish runAction:cleanDishEnter];
    [currentDish runAction:dirtyDishEnter];
    
    // gamestate is now dishwashing
    [self gameStateChanged:2];
}

-(void)doDish
{
    // if the dirty dish is not already clean, gradually reduce the alpha value in time
    if(currentDish.opacity > 0)
        [self schedule:@selector(washTick) interval:0.05 repeat: 1 delay:0];
}

// lets the player know they have died
-(void)killPlayer
{
    scoreLabel.string = @"YOU DIED!";
    scoreLabel.fontColor = [CCColor blackColor];
    leftHand.opacity = 1;
    [water runAction:makeWaterRed];
    [leftHand runAction:tintHandRed];
    
    self.userInteractionEnabled = false;
    
    // in 13 seconds, the gameplay scene begins fading out
    [self performSelector:@selector(fadeOutScene) withObject:self afterDelay:10];
}

-(void)washTick
{
    currentDish.opacity = currentDish.opacity - 0.01;
}

// fades out the scene
-(void)fadeOutScene
{
    fadeOut = [CCActionFadeOut actionWithDuration:4];
    
    // allows the children of the scene to fade out with it
    self.cascadeOpacityEnabled = true;
    
    [self runAction:fadeOut];
    
    // resets the scene after 4 seconds
    [self performSelector:@selector(resetScene) withObject:self afterDelay:4];
}

// a method to perform actions when the state of the game changes
-(void)gameStateChanged : (int)state
{
    gameState = state;
    
    switch (state)
    {
        case 0:
            // when the game loop starts over, updates the player's score and moves lefthand
            displayedScore = displayedScore + 50;
            scoreLabel.string = [NSString stringWithFormat:@"Score: %i", displayedScore];
            moveLeftHand = [CCActionMoveTo actionWithDuration:1.5f position:leftHandRestPos.position];
            [leftHand runAction:moveLeftHand];
            dishHidingPoint.position = [self makeHidingPoint];
            break;
        case 2:
            leftHand.opacity = 1;
            break;
        case 3:
            // moves the sponge to its resting position
            moveSponge = [CCActionMoveTo actionWithDuration:1 position:spongeRestPos.position];
            [sponge runAction:moveSponge];
            break;
        default:
            break;
    }
}

// generates a point in the water to hide the dishHidingPoint in
-(CGPoint)makeHidingPoint
{
    int xMax = 292;
    int yMax = 362;
    int xMin = 20;
    int yMin = 42;
    
    hidingPointX = arc4random()%(xMax-xMin)+xMin;
    hidingPointY = arc4random()%(yMax-yMin)+yMin;
    
    CGPoint hidingPoint = CGPointMake(hidingPointX, hidingPointY);
    
    return hidingPoint;
}

// goes back to the main scene when the player is unlucky enough to get a game over
-(void)resetScene
{
    CCScene *mainScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:mainScene];
}


@end
