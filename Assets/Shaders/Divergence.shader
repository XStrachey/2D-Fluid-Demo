Shader "Custom/Divergence"
{
    Properties
    {
        _VelocityTex("Velocity", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _VelocityTex;
            float2 _MainTex_TexelSize;

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 uv = i.uv;
                float2 L = tex2D(_VelocityTex, uv - float2(_MainTex_TexelSize.x, 0)).xy;
                float2 R = tex2D(_VelocityTex, uv + float2(_MainTex_TexelSize.x, 0)).xy;
                float2 B = tex2D(_VelocityTex, uv - float2(0, _MainTex_TexelSize.y)).xy;
                float2 T = tex2D(_VelocityTex, uv + float2(0, _MainTex_TexelSize.y)).xy;
                float div = (R.x - L.x + T.y - B.y) * 0.5;
                float col = div * 0.5 + 0.5; // 映射到 [0,1]
                return float4(col, col, col, 1);
                return float4(div, 0, 0, 1);
            }
            ENDCG
        }
    }
}
