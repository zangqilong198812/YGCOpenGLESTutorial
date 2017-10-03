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
    GLuint _textureSlot;
    GLuint _textureCoordSlot;
    GLuint _colorSlot;
    
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
    _textureSlot = [shaderCompiler uniformIndex:@"u_Texture"];
    _textureCoordSlot = [shaderCompiler attributeIndex:@"a_TexCoordIn"];
    _colorSlot = [shaderCompiler attributeIndex:@"a_Color"];
}

// step8
- (void)drawTrangle {
    [self activeTexture];
    static const GLfloat vertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1,  1, 0,
        1   ,1, 0
    };   
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    glEnableVertexAttribArray(_textureCoordSlot);
    glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, coords);
    
    static const GLfloat colors[] = {
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1
    };
    
    glEnableVertexAttribArray(_colorSlot);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Texture

- (GLuint)getTextureFromImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    GLubyte* textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    // 4
    glEnable(GL_TEXTURE_2D);
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(textureData);
    return texName;
}

- (void)activeTexture {
    GLuint textureID = [self getTextureFromImage:[UIImage imageNamed:@"wuyanzu.jpg"]];
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glUniform1i(_textureSlot, 5);
}

@end
