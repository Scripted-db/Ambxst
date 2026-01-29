#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec2 texelSize;
} ubuf;

layout(binding = 1) uniform sampler2D source;

void main() {
    float alpha = 0.0;
    float r = clamp(ubuf.radius, 1.0, 32.0);
    float totalWeight = 0.0;
    
    // Using fixed range for compatibility with older GLSL versions
    for (int i = -32; i <= 32; i++) {
        float fi = float(i);
        if (fi < -r || fi > r) continue;
        
        float weight = exp(-0.5 * (fi * fi) / (r * r * 0.25));
        alpha += texture(source, qt_TexCoord0 + vec2(fi * ubuf.texelSize.x, 0.0)).a * weight;
        totalWeight += weight;
    }
    
    fragColor = vec4(0.0, 0.0, 0.0, alpha / totalWeight) * ubuf.qt_Opacity;
}
