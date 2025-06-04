Shader "Custom/Vorticity" {
    Properties {
        _VelocityTex ("Velocity", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _VelocityTex;
            float2 _MainTex_TexelSize;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float2 texel = _MainTex_TexelSize;

                float2 uvL = clamp(uv - float2(texel.x, 0), 0, 1);
                float2 uvR = clamp(uv + float2(texel.x, 0), 0, 1);
                float2 uvB = clamp(uv - float2(0, texel.y), 0, 1);
                float2 uvT = clamp(uv + float2(0, texel.y), 0, 1);

                float L = tex2D(_VelocityTex, uvL).y;
                float R = tex2D(_VelocityTex, uvR).y;
                float B = tex2D(_VelocityTex, uvB).x;
                float T = tex2D(_VelocityTex, uvT).x;
                float curl = (R - L - T + B) * 0.5;
                // curl = saturate(curl * 0.5 + 0.5); // -1~1 -> 0~1 显示
                return float4(curl, 0, 0, 1);
            }
            ENDCG
        }
    }
}