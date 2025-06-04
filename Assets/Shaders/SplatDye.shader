Shader "Custom/SplatDye"
{
    Properties {
        _Point ("Point", Vector) = (0.5, 0.5, 0, 0)
        _Radius ("Radius", Float) = 0.01
        _Color ("Color", Color) = (1, 0.5, 0, 1)
        _DyeTex ("Source", 2D) = "white" {}
        _Aspect ("Aspect", Float) = 1.0
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Point;
            float _Radius;
            float4 _Color;
            sampler2D _DyeTex;
            float _Aspect;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float2 diff = uv - _Point.xy;
                diff.x *= _Aspect;

                float falloff = exp(-dot(diff, diff) / _Radius);

                float4 baseColor = tex2D(_DyeTex, uv);
                float3 addedColor = _Color.rgb * falloff;

                return baseColor + float4(addedColor, 0);
            }
            ENDCG
        }
    }
}
