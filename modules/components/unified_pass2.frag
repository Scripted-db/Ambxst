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
        
        float weight = exp(-0.5 * pow(fi * 3.0 / r, 2.0));
        blurredAlpha += texture(intermediate, shadowCoord + vec2(0.0, fi * ubuf.texelSize.y)).a * weight;
        totalWeight += weight;
    }
    blurredAlpha /= totalWeight;
    
    // Dilation for border
    float dilatedAlpha = 0.0;
    float bw = max(ubuf.borderWidth, 0.0);
    if (bw > 0.0) {
        for (int i = 0; i < 24; i++) {
            float angle = float(i) * (2.0 * 3.14159265 / 24.0);
            vec2 offset = vec2(cos(angle), sin(angle)) * bw;
            dilatedAlpha = max(dilatedAlpha, texture(source, qt_TexCoord0 + offset * ubuf.texelSize).a);
        }
    } else {
        dilatedAlpha = srcAlpha;
    }
    
    // Composition using 'over' blending principles
    vec4 result = srcColor;
    
    // Border: Only outside the source
    float borderMask = clamp(dilatedAlpha - srcAlpha, 0.0, 1.0);
    vec4 border = ubuf.borderColor * borderMask;
    result = result + border * (1.0 - result.a);
    
    // Shadow: Only outside the dilated border
    float shadowMask = clamp(blurredAlpha - dilatedAlpha, 0.0, 1.0);
    vec4 shadow = ubuf.shadowColor * shadowMask;
    result = result + shadow * (1.0 - result.a);
    
    // Handle external mask if enabled
    if (ubuf.maskEnabled > 0.5) {
        float m = texture(maskSource, qt_TexCoord0).a;
        if (ubuf.maskInverted > 0.5) m = 1.0 - m;
        result *= m; // Apply mask to final result
    }
    
    fragColor = result * ubuf.qt_Opacity;
}
