Shader "Custom/Pressure" {
    Properties {
        _PressureTex ("Pressure", 2D) = "white" {}
        _DivergenceTex ("Divergence", 2D) = "white" {}
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _PressureTex;
            sampler2D _DivergenceTex;
            float2 _MainTex_TexelSize;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float L = tex2D(_PressureTex, uv - float2(_MainTex_TexelSize.x, 0)).r;
                float R = tex2D(_PressureTex, uv + float2(_MainTex_TexelSize.x, 0)).r;
                float B = tex2D(_PressureTex, uv - float2(0, _MainTex_TexelSize.y)).r;
                float T = tex2D(_PressureTex, uv + float2(0, _MainTex_TexelSize.y)).r;
                float div = tex2D(_DivergenceTex, uv).r;

                float pressure = (L + R + B + T - div) * 0.25;
                return float4(pressure, 0, 0, 1); // 明确设置输出 alpha
            }
            ENDCG
        }
    }
}
