Shader "TestShader/Face"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightMap ("_LightMap", 2D) = "white" {}
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

        _FaceLightmpOffset ("Face Lightmp Offset", Range(-1, 1)) = 0

        _FresnelPower("FresnelPower",Range(0,1)) = 0.5
        _FresnelScale("FresnelScale",Range(0,1)) =0.2
        _FresnelSmooth("FresnelSmooth",Range(0,1)) = 0.2


        [KeywordEnum(None,LightMap_R,LightMap_G,LightMap_B,LightMap_A,UV,UV2,VertexColor,BaseColor,BaseColor_A)] _TestMode("_TestMode",Int) = 0
    }
    SubShader
    {
        Tags{ "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _ShadowColor;
        float _ShaowRange;
        float _ShadowSmooth;
        float _DiffuseThreshold;
        float _SpecularScale;
        float _SpecularPowerValue;
        float4 _SpecularColor;

        float _Outline;
        float _Factor;
        float4 _OutColor;
        float _FaceLightmpOffset;
        int _TestMode;
        float _FresnelPower;
        float  _FresnelScale;
        float _FresnelSmooth;
         
        CBUFFER_END

        ENDHLSL

        pass
        {
            Cull Off
            Name "FaceMainPass"
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
                float2 uv2 : TEXCOORD1;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor:COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent      : TEXCOORD1;
                float3 bitangent    : TEXCOORD2; 
                float3 normal       : TEXCOORD3; 
                float3 worldPosition: TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal  : TEXCOORD6;
                float4 vertexColor  : TEXCOORD7;
                float2 uv2          : TEXCOORD8;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);
            TEXTURE2D(_ShadowRamp);
            SAMPLER(sampler_ShadowRamp);

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
                o.worldPosition = positionInputs.positionWS;
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
                float4 shadowCoords = TransformWorldToShadowCoord(i.worldPosition.xyz);
                Light light = GetMainLight(shadowCoords);
                float3 lightColor = light.color;
                float3 L = normalize(light.direction);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPosition.xyz);
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
                //float4 faceLightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,float2(uv.x,uv.y));
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

                float3 Fresnel = 1-smoothstep(0,_FresnelSmooth,NV-_FresnelScale);
                Fresnel = clamp(0,_FresnelPower,saturate(Fresnel)) * lightColor;;


                float4 Front = float4(TransformObjectToWorldDir(float3(0,0,1)),0);
                float4 Right = float4(TransformObjectToWorldDir(float3(1,0,0)),0);
                float4 Up = float4(TransformObjectToWorldDir(float3(0,1,0)),0);
                float3 Left = -Right;

                float FL =  dot(normalize(Front.xz), normalize(L.xz));
                float LL = dot(normalize(Left.xz), normalize(L.xz));
                float RL = dot(normalize(Right.xz), normalize(L.xz));
                float4 faceLightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,float2(uv.x,uv.y));
                float4 faceLightMapMir = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,float2(1-uv.x,uv.y));

                float faceLight = faceLightMap.r + _FaceLightmpOffset;
                float faceLightRamp = 0;

                if(FL>0 && LL>0)
                {
                    faceLightRamp =1>faceLightMapMir+LL;
                }else if(FL>0 && RL>0)
                {
                    faceLightRamp =1>faceLightMap+RL;
                }

                float3 Diffuse = lerp( _ShadowColor*BaseColor,BaseColor,faceLightRamp);

                FinalColor = Diffuse  + Fresnel;
                return float4(FinalColor,1);
                
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "TestShader/Skin/Outline"
    }

}
