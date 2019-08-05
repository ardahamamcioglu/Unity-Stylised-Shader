Shader "Custom/StylisedShader" {
	//Author:Arda Hamamcioglu
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _ScreenTex ("Shade Filter Texture", 2D) ="white" {}
		_SpecMap ("Specularity Map",2D) = "white" {}
		_SpecularSize ("Specular Size",Range(0,1)) = 1
		_SpecularIntensity ("Specular Intensity",Range(0,1)) = 1 
		_SpecularAberration ("Specular Aberration",Range(0,1)) = 0
       _RampSteps ("Lighting Ramp Steps", Range(1,7.99)) = 1
	   _TexShade ("Texture Shade Intensity",Range(0,1)) = 0
	   _TexIntensity ("Texture Shape Intensity",Range (0,1)) = 1
	   _PatternSize("Base Pattern Size",Float) = 100
	   _RampIntensity("Ramp Intensity",Range(0,1)) = 0
	   //_DepthScale ("Pattern Depth Scale",Float) = 5
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Stylised fullForwardShadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _SpecMap;
       	sampler2D _ScreenTex;

		float4 _ScreenTex_ST;

		struct StylisedSurfaceOutput{
			fixed3 Albedo;
    		float2 ScreenPos;
    		fixed3 Emission;
    		fixed Alpha;
    		fixed3 Normal;
			fixed Specular;
			//fixed3 WorldPos;
		};

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
			float3 worldPos;
		};

		fixed4 _Color;
		fixed _SpecularSize;
		fixed _SpecularIntensity;
		fixed _SpecularAberration;
       	fixed _RampSteps;
	   	fixed _TexShade;
	   	fixed _TexIntensity;
		fixed _PatternSize;
		fixed _RampIntensity;
		//fixed _DepthScale;

       //LIGTHING MODEL
        half4 LightingStylised (StylisedSurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
			//DEPTH... IF NEEDED SOMEDAY
			//half depth = 1-distance(s.WorldPos,_WorldSpaceCameraPos)/_DepthScale;
			fixed shadeTex = tex2D(_ScreenTex, frac(s.ScreenPos*_PatternSize)).r;
			_RampSteps = (int)_RampSteps;
        	half NdotL = dot(s.Normal, lightDir);
        	half NDLRamp = lerp(pow(NdotL,0.5),round(NdotL*_RampSteps)/_RampSteps-.01,_RampIntensity);
			half DotRamp = (1-NDLRamp)*_TexIntensity;
			half ShadeTex = lerp(NDLRamp,step(shadeTex,NDLRamp-DotRamp),_TexShade);
			//SPECULAR LIGTHING
			fixed3 reflectionDirection = reflect(lightDir,s.Normal);
			fixed towardsReflection = dot(viewDir,-reflectionDirection);
			fixed specularChange = fwidth(towardsReflection);
			fixed spec = smoothstep(1-_SpecularSize,1-_SpecularSize+specularChange,towardsReflection);
			spec *= _SpecularIntensity;
        	half4 c;
        	c.rgb = lerp(ShadeTex,.5+NDLRamp*ceil(lerp(1,towardsReflection,_SpecularAberration)*_LightColor0*(_SpecularSize+1)),spec)*_LightColor0.rgb*s.Albedo*atten;
        	c.a = s.Alpha;
        	return c;
        }

		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

        //SURFACE FUNCTION
	   	void surf (Input i, inout StylisedSurfaceOutput o) {
			fixed4 c = tex2D (_MainTex, i.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;

			float aspect = _ScreenParams.x / _ScreenParams.y;
    		o.ScreenPos = i.screenPos.xy / i.screenPos.w;
    		o.ScreenPos = TRANSFORM_TEX(o.ScreenPos, _ScreenTex);
    		o.ScreenPos.x = o.ScreenPos.x * aspect;
			
			o.Specular = tex2D(_SpecMap,i.uv_MainTex);
			//o.WorldPos = i.worldPos;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
