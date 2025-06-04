Shader "Custom/VorticityForce"
{
    Properties {
        _VelocityTex ("Velocity", 2D) = "white" {}
        _CurlTex ("Curl", 2D) = "white" {}
        _Curl ("Curl Strength", Float) = 2.0
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _VelocityTex;
            sampler2D _CurlTex;
            float _Curl;
            float2 _MainTex_TexelSize;

            float2 gradient(float2 uv) {
                float L = tex2D(_CurlTex, uv - float2(_MainTex_TexelSize.x, 0)).r;
                float R = tex2D(_CurlTex, uv + float2(_MainTex_TexelSize.x, 0)).r;
                float B = tex2D(_CurlTex, uv - float2(0, _MainTex_TexelSize.y)).r;
                float T = tex2D(_CurlTex, uv + float2(0, _MainTex_TexelSize.y)).r;
                return float2(R - L, T - B);
            }

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float curl = tex2D(_CurlTex, uv).r;

                // Clamp curl to avoid wild vorticity
                curl = clamp(curl, -5.0, 5.0);

                float2 grad = gradient(uv);
                float lengthGrad = max(length(grad), 1e-5);
                float2 normGrad = grad / lengthGrad;

                float2 vorticityForce = float2(normGrad.y, -normGrad.x) * clamp(curl, -1.0, 1.0) * _Curl;

                float2 velocity = tex2D(_VelocityTex, uv).xy + vorticityForce;

                return float4(velocity, 0, 1);
            }
            ENDCG
        }
    }
}
