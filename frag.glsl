#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 resolution;
uniform sampler2D texture;
uniform vec2 textureSize;
uniform float speed;
uniform float tolerance;
uniform vec3 colorStart;
uniform vec3 colorEnd;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec4 domainWarp(vec3 color, vec2 st){
   vec2 q = vec2(0.);
    q.x = fbm( st + time);
    q.y = fbm( st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*time);
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*time);

    float f = fbm(st+r);

    color = mix(vec3(0.101961,0.619608,0.666667),
                vec3(0.666667,0.666667,0.498039),
                clamp((f*f)*4.0,0.0,1.0));
                
    color = mix(color,
                vec3(0.666667,1,1),
                clamp(length(r.x),0.0,1.0));
    return vec4((f*f*f*f+.6*f*f+.5*f)*color,1.);
}

vec4 gradiantVideo(float tolerance, vec4 startColor){
  vec2 coord = gl_FragCoord.xy / resolution;
  vec3 videoColor = texture2D( texture, vec2( coord.x, 1. - coord.y) ).xyz;
  // linear color interpolation
  float colorSum = (videoColor.x + videoColor.y + videoColor.z);
  float colorRange = 3. - tolerance; //run
  //color slopes
  float redSlope = (colorEnd.x - colorStart.x)/colorRange;    //rise r
  float greenSlope = (colorEnd.y - colorStart.y)/colorRange;  //rise g
  float blueSlope = (colorEnd.z - colorStart.z)/colorRange;   //rise b
  if(colorSum > tolerance){ 
    startColor.xyz = startColor.xyz + vec3(colorStart.x + (redSlope * (colorSum - tolerance)),
                                           colorStart.y + (greenSlope * (colorSum - tolerance)),
                                           colorStart.z + (blueSlope * (colorSum - tolerance)));
  }
  return startColor;
}

void main() {
    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
    st.x += st.x + abs(sin(time*0.1*speed)*3.);
    st.y += st.y - sin(time*0.1*speed)*3.;
    vec3 color = vec3(1.0,1.,1.);

    vec4 background = domainWarp(color, st);
    background = gradiantVideo(tolerance, background);
    
    gl_FragColor = background;
}