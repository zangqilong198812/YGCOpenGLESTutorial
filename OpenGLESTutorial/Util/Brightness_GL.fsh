precision mediump float;
uniform sampler2D u_Texture;
varying vec2 v_TexCoordOut;
uniform float brightness;

void main()
{
    vec4 textureColor = texture2D(u_Texture, v_TexCoordOut);
    
    gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
}
