attribute vec4 a_Position;
attribute vec2 a_TextureCoordinateIn;

varying vec2 v_TextureCoordinateOut;
varying vec2 v_Position;

void main(void) {
    gl_Position = a_Position;
    v_TextureCoordinateOut = a_TextureCoordinateIn;
    v_Position = vec2(a_Position.x, a_Position.y);
}
