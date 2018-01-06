//
//  ViewController.m
//  OpenGLESTutorial
//
//  Created by zang qilong on 2017/9/29.
//  Copyright © 2017年 zang qilong. All rights reserved.
//

#import "DoubleShaderController.h"
#import <OpenGLES/ES2/gl.h>
#import "ZQLShaderCompiler.h"
#import <AVFoundation/AVFoundation.h>

@interface DoubleShaderController ()
{
    EAGLContext *_eaglContext;
    CAEAGLLayer *_eaglLayer;
    
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    GLuint _brightness;
    GLuint _positionSlot;
    GLuint _textureSlot;
    GLuint _textureCoordSlot;
    
    GLuint _positionSlot2;
    GLuint _textureSlot2;
    GLuint _textureCoordSlot2;
    
    GLuint _offscreenFramebuffer;
    GLuint brightnessTexture;
    
    UIImage *processImage;
    GLint width;
    GLint height;
    GLuint texName;
    
    ZQLShaderCompiler *brightnessShader;
    ZQLShaderCompiler *renderShader;
}
@property (weak, nonatomic) IBOutlet UISlider *brightSlider;
@property (weak, nonatomic) IBOutlet UIButton *getImageButton;

@end

@implementation DoubleShaderController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self setupOpenGLContext];
    processImage = [UIImage imageNamed:@"wuyanzu.jpg"];
    texName = [self getTextureFromImage:processImage];
    
    
    [self setupCAEAGLLayer:self.view.bounds];
    [self clearRenderBuffers];
    [self setupRenderBuffers];
    [self createOffscreenBuffer:processImage];
    [self setupRenderScreenViewPort];
    [self setupRenderShader];
    [self setupBrightnessShader];;
    [self renderToScreen];
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
    [self.view bringSubviewToFront:_brightSlider];
    [self.view bringSubviewToFront:_getImageButton];
    
    
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
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)createOffscreenBuffer:(UIImage *)image {
    glGenFramebuffers(1, &_offscreenFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFramebuffer);
    
    //Create the texture
   
    glGenTextures(1, &brightnessTexture);
    glBindTexture(GL_TEXTURE_2D, brightnessTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //Bind the texture to your FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, brightnessTexture, 0);
    
    //Test if everything failed
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        printf("failed to make complete framebuffer object %x", status);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

// step6
- (void)setupRenderScreenViewPort {
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

// step7
- (void)setupBrightnessShader {
    brightnessShader = [[ZQLShaderCompiler alloc] initWithVertexShader:@"vertexShader.vsh" fragmentShader:@"Brightness_GL.fsh"];
    [brightnessShader prepareToDraw];
    _positionSlot = [brightnessShader attributeIndex:@"a_Position"];
    _textureSlot = [brightnessShader uniformIndex:@"u_Texture"];
    _textureCoordSlot = [brightnessShader attributeIndex:@"a_TexCoordIn"];
    _brightness = [brightnessShader uniformIndex:@"brightness"];
}

- (void)setupRenderShader {
    renderShader = [[ZQLShaderCompiler alloc] initWithVertexShader:@"vertexShader.vsh" fragmentShader:@"fragmentShader.fsh"];
    [renderShader prepareToDraw];
    _positionSlot2 = [renderShader attributeIndex:@"a_Position"];
    _textureSlot2 = [renderShader uniformIndex:@"u_Texture"];
    _textureCoordSlot2 = [renderShader attributeIndex:@"a_TexCoordIn"];

}

// step8
- (void)renderToScreen {
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    [self setupRenderScreenViewPort];
    [renderShader prepareToDraw];

    UIImage *image = processImage;
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.view.bounds);
    CGFloat widthRatio = realRect.size.width/self.view.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.view.bounds.size.height;
    
    const GLfloat vertices[] = {
        -widthRatio, -heightRatio, 0,   //左下
        widthRatio,  -heightRatio, 0,   //右下
        -widthRatio, heightRatio,  0,   //左上
        widthRatio,  heightRatio,  0 }; //右上
    
    const GLfloat originVertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1, 1,  0,   //左上
        1,  1,  0 }; //右上
    
    glEnableVertexAttribArray(_positionSlot2);
    glVertexAttribPointer(_positionSlot2, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    // normal
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    glEnableVertexAttribArray(_textureCoordSlot2);
    glVertexAttribPointer(_textureCoordSlot2, 2, GL_FLOAT, GL_FALSE, 0, coords);
    
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, brightnessTexture);
    glUniform1i(_textureSlot2, 5);

  
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawRawImage {
   // [self activeTexture];
    
    const GLfloat vertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1, 1,  0,   //左上
        1,  1,  0 }; //右上
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    // normal
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    glEnableVertexAttribArray(_textureCoordSlot);
    glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, coords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

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
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
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
    glBindTexture(GL_TEXTURE_2D, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(textureData);
    return texName;
}

- (void)activeTexture {
    
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, texName);
    glUniform1i(_textureSlot, 5);
}

- (IBAction)valueChanged:(UISlider *)sender {
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFramebuffer);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, (GLsizei)processImage.size.width, (GLsizei)processImage.size.height);
    
    [brightnessShader prepareToDraw];
    
    glUniform1f(_brightness, sender.value);
    [self activeTexture];
    
    [self drawRawImage];
    
    UIImage *brightnessImage = [self getImageFromBuffe:(int)processImage.size.width withHeight:(int)processImage.size.height];
    
    [self renderToScreen];
    
}

- (UIImage *)getImageFromBuffe:(int)width withHeight:(int)height {
    GLint x = 0, y = 0;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    return image;
}

- (IBAction)getImage:(id)sender {
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFramebuffer);
    glViewport(0, 0, processImage.size.width, processImage.size.height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [brightnessShader prepareToDraw];
    
    glUniform1f(_brightness, _brightSlider.value);
    [self activeTexture];
    
    [self drawRawImage];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    [self setupRenderScreenViewPort];
    
    //[self getImageFromBuffe:processImage.size.width withHeight:processImage.size.height];
}

@end
