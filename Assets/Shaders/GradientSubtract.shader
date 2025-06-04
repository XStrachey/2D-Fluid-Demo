Shader "Custom/GradientSubtract" {
    Properties {
        _VelocityTex ("Velocity", 2D) = "white" {}
        _PressureTex ("Pressure", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _VelocityTex;
            sampler2D _PressureTex;
            float2 _MainTex_TexelSize;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float L = tex2D(_PressureTex, uv - float2(_MainTex_TexelSize.x, 0)).r;
                float R = tex2D(_PressureTex, uv + float2(_MainTex_TexelSize.x, 0)).r;
                float B = tex2D(_PressureTex, uv - float2(0, _MainTex_TexelSize.y)).r;
                float T = tex2D(_PressureTex, uv + float2(0, _MainTex_TexelSize.y)).r;

                float2 velocity = tex2D(_VelocityTex, uv).xy;
                float2 gradient = float2(R - L, T - B) * 0.5;

                velocity -= gradient;
                return float4(velocity, 0, 1);
            }
            ENDCG
        }
    }
}
