Shader "Custom/Advection" {
    Properties {
        _InputTex ("Input", 2D) = "white" {}
        _VelocityTex ("Velocity", 2D) = "white" {}
        _DeltaTime ("Delta Time", Float) = 0.01
        _Dissipation ("Dissipation", Float) = 0.99
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _InputTex;
            sampler2D _VelocityTex;
            float _DeltaTime;
            float _Dissipation;
            float2 _MainTex_TexelSize;

            fixed4 frag(v2f_img i) : SV_Target {
                float2 uv = i.uv;
                float2 velocity = tex2D(_VelocityTex, uv).xy;
                float2 prevPos = uv - _DeltaTime * velocity * _MainTex_TexelSize.xy;
                return tex2D(_InputTex, prevPos) * _Dissipation; // Apply dissipation to the advection
            }
            ENDCG
        }
    }
}