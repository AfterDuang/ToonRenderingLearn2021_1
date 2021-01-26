Shader "TestShader/Base"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor("BaseColor",Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        //float4 _MainTex;
        float4 _BaseColor;
        float4 _MainTex_ST;
        CBUFFER_END

        ENDHLSL
        Pass
        {
            Name "BasePass"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            
            #pragma vertex vert 
            #pragma fragment frag 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#pragma multi_compile_fwdbase

            //#include "AutoLight.cginc"
            //#include "Lighting.cginc"
            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
            };            

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
                //float3 Color : COLOR;

            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert(a2v v)
            {
                v2f o;
                //o.pos = TransformWorldToHClip(v.vertex);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                //o.Color = _BaseColor;
                return o;
            }  

            float4 frag(v2f i):SV_Target
            {
                float4 color = _BaseColor;
                float4 MainTexTrans = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                //Float4 FinalColor = MainTexTrans * color;

                return MainTexTrans * color;
            }

            ENDHLSL
        }

        pass
        {
           Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
 
            ZWrite On
            ZTest LEqual
 
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
 
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
 
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
             
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
     
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
 
    ENDHLSL 
        }
    }
}
