﻿Shader "Instanced/InstancedIndirectSurfaceShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		// And generate the shadow pass with instancing support
		#pragma surface surf Standard addshadow
//		#pragma surface surfStandard Standard fullforwardshadows addshadow
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		// Enable instancing for this shader
		#pragma multi_compile_instancing
		#pragma instancing_options procedural:setup

		// Config maxcount. See manual page.
		// #pragma instancing_options

		fixed4 _Color;
		half _Glossiness;
		half _Metallic;

		struct Input {
			float2 uv_MainTex;
		};


		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			StructuredBuffer<float3> positions;
			StructuredBuffer<float4> quaternions;
		#endif

		void setup()
		{
		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			float3 position 	= positions[unity_InstanceID];
			float4 q 			= quaternions[unity_InstanceID];
			float qr			= q[0];
			float qi			= q[1];
			float qj			= q[2];
			float qk			= q[3];

			float4x4 rotation;
			float4x4 translation = {
				1,0,0,position.x,
				0,1,0,position.y,
				0,0,1,position.z,
				0,0,0,1
			};

			rotation[0][0]			= 1.0f - 2.0f*qj*qj - 2.0f*qk*qk;
			rotation[0][1]			= 2.0f*(qi*qj - qk*qr);
			rotation[0][2]			= 2.0f*(qi*qk + qj*qr);
			rotation[0][3]			= 0.0f;

			rotation[1][0]			= 2.0f*(qi*qj+qk*qr);
			rotation[1][1]			= 1.0f - 2.0f*qi*qi - 2.0f*qk*qk;
			rotation[1][2]			= 2.0f*(qj*qk - qi*qr);
			rotation[1][3]			= 0.0f;

			rotation[2][0]			= 2.0f*(qi*qk - qj*qr);
			rotation[2][1]			= 2.0f*(qj*qk + qi*qr);
			rotation[2][2]			= 1.0f - 2.0f*qi*qi - 2.0f*qj*qj;
			rotation[2][3]			= 0.0f;

			rotation[3][0]			= 0.0f;
			rotation[3][1]			= 0.0f;
			rotation[3][2]			= 0.0f;
			rotation[3][3]			= 1.0f;
			// quaternion to matrix
			// http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/
			// https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Quaternion-derived_rotation_matrix



//			unity_ObjectToWorld._11_21_31_41 = float4(1, 0, 0, 0);
//			unity_ObjectToWorld._12_22_32_42 = float4(0, 1, 0, 0);
//			unity_ObjectToWorld._13_23_33_43 = float4(0, 0, 1, 0);
//			unity_ObjectToWorld._14_24_34_44 = float4(position.xyz, 1);
			//unity_ObjectToWorld = rotation;
			unity_ObjectToWorld = mul(translation, rotation);

			
			// inverse transform matrix
			// taken from richardkettlewell's post on
			// https://forum.unity3d.com/threads/drawmeshinstancedindirect-example-comments-and-questions.446080/

			float3x3 w2oRotation;
			w2oRotation[0] = unity_ObjectToWorld[1].yzx * unity_ObjectToWorld[2].zxy - unity_ObjectToWorld[1].zxy * unity_ObjectToWorld[2].yzx;
			w2oRotation[1] = unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[2].yzx - unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[2].zxy;
			w2oRotation[2] = unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[1].zxy - unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[1].yzx;

			float det = dot(unity_ObjectToWorld[0], w2oRotation[0]);

			w2oRotation = transpose(w2oRotation);

			w2oRotation *= rcp(det);

			float3 w2oPosition = mul(w2oRotation, -unity_ObjectToWorld._14_24_34);

			unity_WorldToObject._11_21_31_41 = float4(w2oRotation._11_21_31, 0.0f);
			unity_WorldToObject._12_22_32_42 = float4(w2oRotation._12_22_32, 0.0f);
			unity_WorldToObject._13_23_33_43 = float4(w2oRotation._13_23_33, 0.0f);
			unity_WorldToObject._14_24_34_44 = float4(w2oPosition, 1.0f);
		#endif
		}


		// Declare instanced properties inside a cbuffer.
		// Each instanced property is an array of by default 500(D3D)/128(GL) elements. Since D3D and GL imposes a certain limitation
		// of 64KB and 16KB respectively on the size of a cubffer, the default array size thus allows two matrix arrays in one cbuffer.
		// Use maxcount option on #pragma instancing_options directive to specify array size other than default (divided by 4 when used
		// for GL).
		//UNITY_INSTANCING_CBUFFER_START(Props)
		//	UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)	// Make _Color an instanced property (i.e. an array)
		//UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
