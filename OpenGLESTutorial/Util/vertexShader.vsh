attribute vec4 a_Position;

attribute vec2 a_TexCoordIn;
varying vec2 v_TexCoordOut;
varying vec4 a_position_out;

void main(void) {
    gl_Position = a_Position;
    v_TexCoordOut = a_TexCoordIn;
    a_position_out = a_Position;
}
