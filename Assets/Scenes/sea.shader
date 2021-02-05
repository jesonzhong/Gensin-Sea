Shader "Unlit/sea"
{
	Properties
	{
    	_sharowBlue("sharrowBlue", Color) = (.34, .85, .92, 1) // カラー
	    _deepBlue("deepBlue", Color) = (.34, .85, .92, 1) // カラー

		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha 

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;

				float3 worldNormal : TEXCOORD1;
				float4 projPos : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			uniform float4 _sharowBlue;
			uniform float4 _deepBlue;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				
				o.projPos = ComputeScreenPos(o.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal); 
				COMPUTE_EYEDEPTH(o.projPos.z);
				return o;
			}
			
			fixed4 cosine_gradient(float x,  fixed4 phase, fixed4 amp, fixed4 freq, fixed4 offset){
				const float TAU = 2. * 3.14159265;
  				phase *= TAU;
  				x *= TAU;

  				return fixed4(
    				offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
    				offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
    				offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
    				offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
  				);
			}
			fixed3 toRGB(fixed3 grad){
  				 return grad.rgb;
			}

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);	
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

    			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float po = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos));


				float partZ = i.projPos.z;

				float volmeZ = clamp(
					(sceneZ - partZ)/10.0f,
					0,
					1
				);

				const fixed4 phases = fixed4(0.28, 0.50, 0.07, 0.);
				const fixed4 amplitudes = fixed4(4.02, 0.34, 0.65, 0.);
				const fixed4 frequencies = fixed4(0.00, 0.48, 0.08, 0.);
				const fixed4 offsets = fixed4(0.00, 0.16, 0.00, 0.);

				fixed4 cos_grad = cosine_gradient(1-volmeZ, phases, amplitudes, frequencies, offsets);
  				cos_grad = clamp(cos_grad, 0., 1.);
				
  				col.rgb = toRGB(cos_grad);
					
				half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 reflDir = reflect(-worldViewDir, i.worldNormal);
				fixed4 reflectionColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0);
				col = lerp(col , reflectionColor , 0.5);

				float alpha = clamp(volmeZ/1.0f ,0,1);
  				col.a = alpha;
				return col;
			}
			ENDCG
		}
	}
}
