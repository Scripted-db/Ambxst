#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec2 texelSize;
    float borderWidth;
    vec4 borderColor;
    vec4 shadowColor;
    vec2 shadowOffset;
    float maskEnabled;
    float maskInverted;
} ubuf;

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D intermediate;
layout(binding = 3) uniform sampler2D maskSource;

void main() {
    vec4 srcColor = texture(source, qt_TexCoord0);
    float srcAlpha = srcColor.a;
    
    // Vertical blur for shadow
    float blurredAlpha = 0.0;
    float r = clamp(ubuf.radius, 1.0, 32.0);
    float totalWeight = 0.0;
    
    vec2 shadowCoord = qt_TexCoord0 - ubuf.shadowOffset * ubuf.texelSize;
    
    for (int i = -32; i <= 32; i++) {
        float fi = float(i);
        if (fi < -r || fi > r) continue;
        
        float weight = exp(-0.5 * (fi * fi) / (r * r * 0.25));
        blurredAlpha += texture(intermediate, shadowCoord + vec2(0.0, fi * ubuf.texelSize.y)).a * weight;
        totalWeight += weight;
    }
    blurredAlpha /= totalWeight;
    
    // Dilation for border
    float dilatedAlpha = 0.0;
    float bw = clamp(ubuf.borderWidth, 0.0, 8.0);
    if (bw > 0.0) {
        for (int x = -8; x <= 8; x++) {
            float fx = float(x);
            if (fx < -bw || fx > bw) continue;
            for (int y = -8; y <= 8; y++) {
                float fy = float(y);
                if (fy < -bw || fy > bw) continue;
                
                if (fx*fx + fy*fy <= (bw + 0.5)*(bw + 0.5)) {
                    dilatedAlpha = max(dilatedAlpha, texture(source, qt_TexCoord0 + vec2(fx, fy) * ubuf.texelSize).a);
                }
            }
        }
    } else {
        dilatedAlpha = srcAlpha;
    }
    
    float cutoff = 0.02;
    float aa = 0.01; 
    float inside = smoothstep(cutoff - aa, cutoff + aa, srcAlpha);
    
    float shadowMask = clamp(blurredAlpha - srcAlpha, 0.0, 1.0) * (1.0 - inside);
    float borderMask = clamp(dilatedAlpha - srcAlpha, 0.0, 1.0) * (1.0 - inside);
    
    if (ubuf.maskEnabled > 0.5) {
        float m = texture(maskSource, qt_TexCoord0).a;
        if (ubuf.maskInverted > 0.5) m = 1.0 - m;
        shadowMask *= m;
        borderMask *= m;
    }
    
    vec4 shadow = ubuf.shadowColor * shadowMask;
    vec4 border = ubuf.borderColor * borderMask;
    
    vec4 result = srcColor + border + shadow;
    
    fragColor = result * ubuf.qt_Opacity;
}
