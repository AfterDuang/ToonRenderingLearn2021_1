Shader "TestShader/Body"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ShadowColor("Color",Color) = (0.5,0.5,0.5,0.5)
        _MainTex ("MainTex", 2D) = "white" {}
        _StepScale("stepScale",Range(-1,1)) =0.5
        _StepSmooth("StepSmooth",Range(0,1)) = 0.2
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _SpecularPower("SpecularPower",Range(0,3)) = 1
        _SpecularScale("SpecularScale",Range(0,3)) = 1

    }
    SubShader
    {
        Tags{ "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _Color;
        float _StepScale;
        float3 _ShadowColor;
        float _StepSmooth;
        float _SpecularPower;
        float _SpecularScale;
        float3 _SpecularColor;
         
        CBUFFER_END

        ENDHLSL

        pass
        {
            Cull Off
            Name "BodyMainPass"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert 
            #pragma fragment frag 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v 
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 ViewDir : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
                o.ViewDir = positionInputs.positionVS;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal.xyz);
                o.worldNormal = normalInputs.normalWS;
                return o;
            }

            float4 frag(v2f i):SV_TARGET
            {
                float4 shadowCoord = TransformWorldToShadowCoord(i.pos.xyz);
                Light light = GetMainLight(shadowCoord);
                float3 ViewDir = i.ViewDir;
                float3 lightDir = light.direction;
                float3 lightColor = light.color;
                float3 H = ViewDir + lightDir;
                float3 spec = dot(i.worldNormal,H);

                //diffuse
                float3 diff = dot(i.worldNormal,lightDir);
                float3 smoothSetpdiff = smoothstep(-_StepSmooth,_StepSmooth,diff-_StepScale) ;
                float3 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).rgb * _Color;
                float3 diffuse = lerp(_ShadowColor * texColor,texColor,smoothSetpdiff) * lightColor;
                //float3 diffuse = texColor* lightColor;
                //specular

                float3 Specular = 0;
                Specular = texColor * pow(saturate(spec),_SpecularPower)*_SpecularScale;
                Specular =max(Specular,0);

                float3 FinalColor;
                FinalColor = diffuse;

                return float4(FinalColor,1.0);
                
            }

            ENDHLSL
        }
        UsePass "TestShader/Base/ShadowCaster"

    }
}
