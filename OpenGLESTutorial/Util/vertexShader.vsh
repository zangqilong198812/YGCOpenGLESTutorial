attribute vec4 a_Position;

//attribute vec2 a_TexCoordIn;
//varying vec2 v_TexCoordOut;

attribute vec4 a_Color;
varying lowp vec4 v_Color;

void main(void) {
    gl_Position = a_Position;
   // v_TexCoordOut = a_TexCoordIn;
    v_Color = a_Color;
}
