//
//  ViewController.m
//  OpenGLESTutorial
//
//  Created by zang qilong on 2017/9/29.
//  Copyright © 2017年 zang qilong. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES2/gl.h>
#import "ZQLShaderCompiler.h"

@interface ViewController ()
{
    EAGLContext *_eaglContext;
    CAEAGLLayer *_eaglLayer;
    
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
    
    ZQLShaderCompiler *shaderCompiler;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupOpenGLContext];
    [self setupCAEAGLLayer:self.view.bounds];
    [self clearRenderBuffers];
    [self setupRenderBuffers];
    [self setupViewPort];
    [self setupShader];
    [self drawTrangle];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setup GL ES

// step1
- (void)setupOpenGLContext {
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //opengl es 2.0
    [EAGLContext setCurrentContext:_eaglContext]; //设置为当前上下文。
}

// step2
- (void)setupCAEAGLLayer:(CGRect)rect {
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = rect;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:_eaglLayer];
}

// step3
- (void)clearRenderBuffers {
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
}

// step4
- (void)setupRenderBuffers {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    GLint width = 0;
    GLint height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

// step6
- (void)setupViewPort {
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

// step7
- (void)setupShader {
    shaderCompiler = [[ZQLShaderCompiler alloc] initWithVertexShader:@"vertexShader.vsh" fragmentShader:@"fragmentShader.fsh"];
    [shaderCompiler prepareToDraw];
    _positionSlot = [shaderCompiler attributeIndex:@"a_Position"];
}

// step8
- (void)drawTrangle {
    static const GLfloat vertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1, 1,  0};   //左上
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

@end
