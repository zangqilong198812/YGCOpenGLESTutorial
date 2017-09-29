//
//  ZQLShaderCompiler.h
//  OpenGLESTutorial
//
//  Created by zang qilong on 2017/9/29.
//  Copyright © 2017年 zang qilong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface ZQLShaderCompiler : NSObject

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

- (void)prepareToDraw;

- (GLuint)uniformIndex:(NSString *)uniformName;

- (GLuint)attributeIndex:(NSString *)attributeName;

@end
