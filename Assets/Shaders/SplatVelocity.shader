Shader "Custom/SplatVelocity"
{
    Properties {
        _Point ("Point", Vector) = (0.5, 0.5, 0, 0)
        _Radius ("Radius", Float) = 0.01
        _Velocity ("Velocity", Vector) = (1, 0, 0, 0)
        _VelocityTex ("Source", 2D) = "white" {}
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
            float4 _Velocity;
            sampler2D _VelocityTex;
            float _Aspect;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float2 diff = uv - _Point.xy;
                diff.x *= _Aspect;

                float falloff = exp(-dot(diff, diff) / _Radius);

                float4 baseVel = tex2D(_VelocityTex, uv);
                float2 addedVel = _Velocity.xy * falloff;

                float2 newVel = baseVel.xy + addedVel;
                return float4(baseVel.xy + addedVel, baseVel.zw);
            }
            ENDCG
        }
    }
}
