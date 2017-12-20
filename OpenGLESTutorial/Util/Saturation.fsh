precision mediump float;
uniform sampler2D u_Texture;
varying vec2 v_TexCoordOut;
const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
uniform lowp float saturation;

void main(void) {
    vec4 color = texture2D(u_Texture, v_TexCoordOut);
    float lumiance = dot(color.rgb, W);
    vec3 grayScale = vec3(lumiance);
    gl_FragColor = vec4(mix(grayScale, color.rgb, 2.0), 1.0);
    
}
