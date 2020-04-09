//
//  Shaders.metal
//  MyMetalCustomShader
//
//  Created by 竹ノ内朝陽 on 2020/04/09.
//  Copyright © 2020 竹ノ内朝陽. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInOut
{
    float4 position [[ position ]];
};

vertex VertexInOut vertexShader(constant float4 *positions [[ buffer(0) ]], uint vid [[ vertex_id ]])
{
    VertexInOut out;
    out.position = positions[vid];
    return out;
}

float2 hash(float2 p)
{
    float2x2 m = float2x2(13.85, 47.77, 99.41, 88.48);
    return fract(sin(m*p) * 46738.29);
}

float voronoi(float2 p)
{
    float2 g = floor(p);
    float2 f = fract(p);

    float distanceToClosestFeaturePoint = 1.6;
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            float2 latticePoint = float2(x, y);
            float currentDistance = distance(latticePoint + hash(g+latticePoint), f);
            distanceToClosestFeaturePoint = min(distanceToClosestFeaturePoint, currentDistance);
        }
    }

    return distanceToClosestFeaturePoint;
}

fragment float4 fragmentShader(VertexInOut in [[ stage_in ]], constant float2 &resolution [[ buffer(0) ]], constant float &time [[ buffer(1) ]])
{
    float4 position = in.position;
    
    float2 uv = ( position.xy / resolution.xy ) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    float offset = voronoi(uv*10.0 + float2(time));
    float t = 1.0/abs(((uv.x + sin(uv.y + time)) + offset) * 30.0);

    float r = voronoi( uv * 1.0 ) * 10.0;
    float3 finalColor = float3(10.0 * uv.y, 2.0, 1.0 * r) * t;
    
    return float4(finalColor, 1.0);
}
