//
//  ZQLShaderCompiler.m
//  OpenGLESTutorial
//
//  Created by zang qilong on 2017/9/29.
//  Copyright © 2017年 zang qilong. All rights reserved.
//

#import "ZQLShaderCompiler.h"

@interface ZQLShaderCompiler ()

@property (nonatomic, assign) GLuint programHandle;

@end

@implementation ZQLShaderCompiler

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    if (self = [super init]) {
        [self compileVertexShader:vertexShader fragmentShader:fragmentShader];
    }
    
    return self;
}

- (void)prepareToDraw {
    glUseProgram(_programHandle);
}

#pragma mark - Private Method

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *path = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"%@", error.localizedDescription);
    }
    
    const char * shaderUTF8 = [shaderString UTF8String];
    GLint shaderLength = (GLint)[shaderString length];
    GLuint shaderHandle = glCreateShader(shaderType);
    glShaderSource(shaderHandle, 1, &shaderUTF8, &shaderLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandle;
}

- (void)compileVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    GLuint vertexShaderName = [self compileShader:vertexShader withType:GL_VERTEX_SHADER];
    GLuint fragmenShaderName = [self compileShader:fragmentShader withType:GL_FRAGMENT_SHADER];
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShaderName);
    glAttachShader(_programHandle, fragmenShaderName);
    
    
    glLinkProgram(_programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
}

- (GLuint)uniformIndex:(NSString *)uniformName {
    return glGetUniformLocation(_programHandle, [uniformName UTF8String]);
}

- (GLuint)attributeIndex:(NSString *)attributeName {
    return glGetAttribLocation(_programHandle, [attributeName UTF8String]);
}

@end
