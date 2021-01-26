Shader "TestShader/Skin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightMap ("_LightMap", 2D) = "white" {}
        _StaticShadwoClolr("StaticShadwoClolr",Color) = (0.5,0.5,0.5,0.5)
        _ShadowRamp ("_ShadowRamp", 2D) = "white" {}

        _ShadowColor("_ShadowColor",Color) = (0.2,0.2,0.2,0.2)

        _ShadowRange ("Shadow Range", Range(-1, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.2

        _DiffuseThreshold("_DiffuseThreshold",Float)  =0
        _SpecularScale("_SpecularScale",Float) =1
        _SpecularPowerValue("_SpecularPowerValue",Float) =1
        _SpecularColor("_SpecularColor",Color) = (1,1,1,1)
        
        _Outline("Thick of Outline",Float) = 0.01
		_Factor("Factor",range(0,1)) = 0.5
		_OutColor("OutColor",color) = (0,0,0,0)
        _Emssion("Emission",Range(0,1)) = 0

        [KeywordEnum(None,LightMap_R,LightMap_G,LightMap_B,LightMap_A,UV,UV2,VertexColor,BaseColor,BaseColor_A)] _TestMode("_TestMode",Int) = 0
    }
    SubShader
    {
        Tags{ "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _ShadowColor;
        float _ShadowRange;
        float _ShadowSmooth;
        float _DiffuseThreshold;
        float _SpecularScale;
        float _SpecularPowerValue;
        float4 _SpecularColor;
        float _Outline;
        float _Factor;
        float4 _OutColor;
        int _TestMode;
        float3 _StaticShadwoClolr;
        float _Emssion;

        CBUFFER_END

        ENDHLSL

        pass
        {
            Cull Off
            Name "SkinMainPass"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert 
            #pragma fragment frag 

            struct appdata 
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent:TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor:Color;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition : TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal : TEXCOORD6;
                float4 vertexColor : TEXCOORD7;
                float2 uv2 : TEXCOORD8;
            };

            TEXTURE2D(_MainTex);
            TEXTURE2D(_LightMap);
            TEXTURE2D(_ShadowRamp);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_LightMap);
            SAMPLER(sampler_ShadowRamp);
            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
                VertexNormalInputs tbn = GetVertexNormalInputs(v.normal,v.tangent);
                o.normal = tbn.normalWS;
                o.tangent = tbn.tangentWS;
                o.bitangent = tbn.bitangentWS;
                o.localPosition = v.vertex.xyz;
                o.localNormal = v.normal;
                o.vertexColor = v.vertexColor;
                o.uv = v.uv;
                o.uv2 = v.uv2;
                return o;
            }

            float4 frag(v2f i):SV_TARGET
            {
                float3 T = normalize(i.tangent);
                float3 B = normalize(i.bitangent);
                float3 N = normalize(i.normal);
                float4 shadowCoords = TransformWorldToShadowCoord(i.pos.xyz);
                Light light = GetMainLight(shadowCoords);
                float3 lightColor = light.color;
                float3 L = normalize(light.direction);
                float3 V = normalize(_WorldSpaceCameraPos - i.pos.xyz);
                float3 H = normalize(V+L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                float4 vertexColor = i.vertexColor;

                float HV = dot(H,V);
                float NV = dot(N,V);
                float NL = dot(N,L);
                float NH = dot(N,H);

                float3 FinalColor = 0;
                float4 BaseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);
                float4 LightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,uv);

                int mode = 1;
                if(_TestMode == mode++)
                    return LightMap.r;
                if(_TestMode ==mode++)
                    return LightMap.g; //阴影 Mask
                if(_TestMode ==mode++)
                    return LightMap.b; //漫反射 Mask
                if(_TestMode ==mode++)
                    return LightMap.a; //漫反射 Mask
                if(_TestMode ==mode++)
                    return float4(uv,0,0); //uv
                if(_TestMode ==mode++)
                    return float4(uv2,0,0); //uv2
                if(_TestMode ==mode++)
                    return vertexColor.xyzz; //vertexColor
                if(_TestMode ==mode++)
                    return BaseColor.xyzz; //BaseColor
                if(_TestMode ==mode++)
                    return BaseColor.a; //BaseColor.a

                
                float halfLambert = 0.5 * NL + 0.5;
                float rampValue = smoothstep(0,_ShadowSmooth,halfLambert - _ShadowRange);
                float3 ramp = SAMPLE_TEXTURE2D(_ShadowRamp,sampler_ShadowRamp,float2(saturate(rampValue),0.5));
                float3 Diffuse = lerp(_ShadowColor * BaseColor,BaseColor,ramp);

                float3 Specular = 0;

                Specular = pow(saturate(NH),_SpecularPowerValue * LightMap.r) * _SpecularScale * LightMap.b;
                Specular = max(Specular,0);

                float3 staticShadow =saturate( LightMap.g + _StaticShadwoClolr);

                //float3 Emission = BaseColor * LightMap.a * _SkinClolr;
                float3 Emission = LightMap.a * _Emssion;

                FinalColor =(Diffuse+ Specular + Emission) * staticShadow;
                //FinalColor =Emission ;
                
                return float4(FinalColor,1);

                
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}
