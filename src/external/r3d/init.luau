--!strict
-- R3D Lua/Luau FFI Bindings
-- Complete bindings for r3d 3D rendering library

local ffi = zune.ffi

-- Basic types
local void = ffi.types.void
local int = ffi.types.i32
local uint = ffi.types.u32
local float = ffi.types.float
local bool = ffi.types.u8
local voidptr = ffi.types.pointer
local _floatptr = ffi.types.pointer

local function fn(returns: any, args: { any })
	return { returns = returns, args = args }
end

-- R3D Types
export type R3D_Light = number
export type R3D_Flags = number
export type R3D_Layer = number
export type R3D_BlendMode = number
export type R3D_CullMode = number
export type R3D_ShadowCastMode = number
export type R3D_DepthMode = number
export type R3D_BillboardMode = number
export type R3D_LightType = number
export type R3D_ShadowUpdateMode = number
export type R3D_Bloom = number
export type R3D_Fog = number
export type R3D_Tonemap = number
export type R3D_Dof = number

type R3DFns = {
	R3D_Init: (resWidth: number, resHeight: number, flags: number) -> (),
	R3D_Close: () -> (),
	R3D_HasState: (flag: number) -> boolean,
	R3D_SetState: (flags: number) -> (),
	R3D_ClearState: (flags: number) -> (),
	R3D_GetResolution: (width: FFIPointer, height: FFIPointer) -> (),
	R3D_UpdateResolution: (width: number, height: number) -> (),
	R3D_SetTextureFilter: (filter: number) -> (),
	R3D_GetActiveLayers: () -> number,
	R3D_SetActiveLayers: (layers: number) -> (),
	R3D_EnableLayers: (bitfield: number) -> (),
	R3D_DisableLayers: (bitfield: number) -> (),
	R3D_Begin: (camera: FFIPointer) -> (),
	R3D_BeginEx: (camera: FFIPointer, target: FFIPointer?) -> (),
	R3D_End: () -> (),
	R3D_DrawMesh: (mesh: FFIPointer, material: FFIPointer?, transform: FFIPointer) -> (),
	R3D_DrawModel: (model: FFIPointer, position: FFIPointer, scale: number) -> (),
	R3D_DrawModelEx: (
		model: FFIPointer,
		position: FFIPointer,
		rotationAxis: FFIPointer,
		rotationAngle: number,
		scale: FFIPointer
	) -> (),
	R3D_DrawModelPro: (model: FFIPointer, transform: FFIPointer) -> (),
	R3D_DrawSprite: (sprite: FFIPointer, position: FFIPointer) -> (),
	R3D_DrawSpriteEx: (sprite: FFIPointer, position: FFIPointer, size: FFIPointer, rotation: number) -> (),
	R3D_GenMeshPlane: (width: number, length: number, resX: number, resZ: number, upload: boolean) -> FFIPointer,
	R3D_GenMeshCube: (width: number, height: number, length: number, upload: boolean) -> FFIPointer,
	R3D_GenMeshSphere: (radius: number, rings: number, slices: number, upload: boolean) -> FFIPointer,
	R3D_GenMeshCylinder: (radius: number, height: number, slices: number, upload: boolean) -> FFIPointer,
	R3D_UnloadMesh: (mesh: FFIPointer) -> (),
	R3D_UploadMesh: (mesh: FFIPointer, dynamic: boolean) -> boolean,
	R3D_GetDefaultMaterial: () -> FFIPointer,
	R3D_UnloadMaterial: (material: FFIPointer) -> (),
	R3D_LoadModel: (filePath: string) -> FFIPointer,
	R3D_LoadModelFromMemory: (data: FFIPointer, size: number) -> FFIPointer,
	R3D_LoadModelFromMesh: (mesh: FFIPointer) -> FFIPointer,
	R3D_UnloadModel: (model: FFIPointer, unloadMaterials: boolean) -> (),
	R3D_LoadModelAnimations: (filePath: string, animCount: FFIPointer, targetFrameRate: number) -> FFIPointer,
	R3D_UnloadModelAnimations: (animations: FFIPointer, animCount: number) -> (),
	R3D_CreateLight: (type_: number) -> number,
	R3D_DestroyLight: (id: number) -> (),
	R3D_IsLightExist: (id: number) -> boolean,
	R3D_GetLightType: (id: number) -> number,
	R3D_IsLightActive: (id: number) -> boolean,
	R3D_ToggleLight: (id: number) -> (),
	R3D_SetLightActive: (id: number, active: boolean) -> (),
	R3D_SetLightColor: (id: number, r: number, g: number, b: number, a: number) -> (),
	R3D_SetLightPosition: (id: number, x: number, y: number, z: number) -> (),
	R3D_SetLightDirection: (id: number, x: number, y: number, z: number) -> (),
	R3D_LightLookAt: (
		id: number,
		px: number,
		py: number,
		pz: number,
		tx: number,
		ty: number,
		tz: number
	) -> (),
	R3D_SetLightEnergy: (id: number, energy: number) -> (),
	R3D_SetLightSpecular: (id: number, specular: number) -> (),
	R3D_SetLightRange: (id: number, range: number) -> (),
	R3D_SetLightAttenuation: (id: number, attenuation: number) -> (),
	R3D_SetLightInnerCutOff: (id: number, degrees: number) -> (),
	R3D_SetLightOuterCutOff: (id: number, degrees: number) -> (),
	R3D_EnableShadow: (id: number, resolution: number) -> (),
	R3D_DisableShadow: (id: number, destroyMap: boolean) -> (),
	R3D_IsShadowEnabled: (id: number) -> boolean,
	R3D_SetShadowUpdateMode: (id: number, mode: number) -> (),
	R3D_UpdateShadowMap: (id: number) -> (),
	R3D_SetShadowSoftness: (id: number, softness: number) -> (),
	R3D_LoadSprite: (texture: FFIPointer, xFrameCount: number, yFrameCount: number) -> FFIPointer,
	R3D_UnloadSprite: (sprite: FFIPointer) -> (),
	R3D_UpdateSprite: (sprite: FFIPointer, speed: number) -> (),
	R3D_LoadSkybox: (filePath: string, layout: number) -> FFIPointer,
	R3D_LoadSkyboxPanorama: (filePath: string, size: number) -> FFIPointer,
	R3D_UnloadSkybox: (sky: FFIPointer) -> (),
	R3D_EnableSkybox: (skybox: FFIPointer) -> (),
	R3D_DisableSkybox: () -> (),
	R3D_SetSkyboxRotation: (pitch: number, yaw: number, roll: number) -> (),
	R3D_SetSkyboxIntensity: (background: number, ambient: number, reflection: number) -> (),
	R3D_SetBackgroundColor: (r: number, g: number, b: number, a: number) -> (),
	R3D_SetAmbientColor: (r: number, g: number, b: number, a: number) -> (),
	R3D_SetAmbientEnergy: (energy: number) -> (),
	R3D_SetSSAO: (enabled: boolean) -> (),
	R3D_SetSSAORadius: (value: number) -> (),
	R3D_SetSSAOBias: (value: number) -> (),
	R3D_SetSSAOIntensity: (value: number) -> (),
	R3D_SetBloomMode: (mode: number) -> (),
	R3D_SetBloomIntensity: (value: number) -> (),
	R3D_SetBloomThreshold: (value: number) -> (),
	R3D_SetSSR: (enabled: boolean) -> (),
	R3D_SetFogMode: (mode: number) -> (),
	R3D_SetFogColor: (r: number, g: number, b: number, a: number) -> (),
	R3D_SetFogStart: (value: number) -> (),
	R3D_SetFogEnd: (value: number) -> (),
	R3D_SetFogDensity: (value: number) -> (),
	R3D_SetDofMode: (mode: number) -> (),
	R3D_SetDofFocusPoint: (value: number) -> (),
	R3D_SetDofFocusScale: (value: number) -> (),
	R3D_SetTonemapMode: (mode: number) -> (),
	R3D_SetTonemapExposure: (value: number) -> (),
	R3D_SetBrightness: (value: number) -> (),
	R3D_SetContrast: (value: number) -> (),
	R3D_SetSaturation: (value: number) -> (),
}

local defs = {
	R3D_Init = fn(void, { int, int, uint }),
	R3D_Close = fn(void, {}),
	R3D_HasState = fn(bool, { uint }),
	R3D_SetState = fn(void, { uint }),
	R3D_ClearState = fn(void, { uint }),
	R3D_GetResolution = fn(void, { voidptr, voidptr }),
	R3D_UpdateResolution = fn(void, { int, int }),
	R3D_SetTextureFilter = fn(void, { int }),
	R3D_GetActiveLayers = fn(uint, {}),
	R3D_SetActiveLayers = fn(void, { uint }),
	R3D_EnableLayers = fn(void, { uint }),
	R3D_DisableLayers = fn(void, { uint }),

	R3D_Begin = fn(void, { voidptr }),
	R3D_BeginEx = fn(void, { voidptr, voidptr }),
	R3D_End = fn(void, {}),
	R3D_DrawMesh = fn(void, { voidptr, voidptr, voidptr }),
	R3D_DrawModel = fn(void, { voidptr, voidptr, float }),
	R3D_DrawModelEx = fn(void, { voidptr, voidptr, voidptr, float, voidptr }),
	R3D_DrawModelPro = fn(void, { voidptr, voidptr }),
	R3D_DrawSprite = fn(void, { voidptr, voidptr }),
	R3D_DrawSpriteEx = fn(void, { voidptr, voidptr, voidptr, float }),

	R3D_GenMeshPlane = fn(voidptr, { float, float, int, int, bool }),
	R3D_GenMeshCube = fn(voidptr, { float, float, float, bool }),
	R3D_GenMeshSphere = fn(voidptr, { float, int, int, bool }),
	R3D_GenMeshCylinder = fn(voidptr, { float, float, int, bool }),
	R3D_UnloadMesh = fn(void, { voidptr }),
	R3D_UploadMesh = fn(bool, { voidptr, bool }),

	R3D_GetDefaultMaterial = fn(voidptr, {}),
	R3D_UnloadMaterial = fn(void, { voidptr }),

	R3D_LoadModel = fn(voidptr, { voidptr }),
	R3D_LoadModelFromMemory = fn(voidptr, { voidptr, uint }),
	R3D_LoadModelFromMesh = fn(voidptr, { voidptr }),
	R3D_UnloadModel = fn(void, { voidptr, bool }),
	R3D_LoadModelAnimations = fn(voidptr, { voidptr, voidptr, int }),
	R3D_UnloadModelAnimations = fn(void, { voidptr, int }),

	R3D_CreateLight = fn(uint, { int }),
	R3D_DestroyLight = fn(void, { uint }),
	R3D_IsLightExist = fn(bool, { uint }),
	R3D_GetLightType = fn(int, { uint }),
	R3D_IsLightActive = fn(bool, { uint }),
	R3D_ToggleLight = fn(void, { uint }),
	R3D_SetLightActive = fn(void, { uint, bool }),
	R3D_SetLightColor = fn(void, { uint, float, float, float, float }),
	R3D_SetLightPosition = fn(void, { uint, float, float, float }),
	R3D_SetLightDirection = fn(void, { uint, float, float, float }),
	R3D_LightLookAt = fn(void, { uint, float, float, float, float, float, float }),
	R3D_SetLightEnergy = fn(void, { uint, float }),
	R3D_SetLightSpecular = fn(void, { uint, float }),
	R3D_SetLightRange = fn(void, { uint, float }),
	R3D_SetLightAttenuation = fn(void, { uint, float }),
	R3D_SetLightInnerCutOff = fn(void, { uint, float }),
	R3D_SetLightOuterCutOff = fn(void, { uint, float }),

	R3D_EnableShadow = fn(void, { uint, int }),
	R3D_DisableShadow = fn(void, { uint, bool }),
	R3D_IsShadowEnabled = fn(bool, { uint }),
	R3D_SetShadowUpdateMode = fn(void, { uint, int }),
	R3D_UpdateShadowMap = fn(void, { uint }),
	R3D_SetShadowSoftness = fn(void, { uint, float }),

	R3D_LoadSprite = fn(voidptr, { voidptr, int, int }),
	R3D_UnloadSprite = fn(void, { voidptr }),
	R3D_UpdateSprite = fn(void, { voidptr, float }),

	R3D_LoadSkybox = fn(voidptr, { voidptr, int }),
	R3D_LoadSkyboxPanorama = fn(voidptr, { voidptr, int }),
	R3D_UnloadSkybox = fn(void, { voidptr }),
	R3D_EnableSkybox = fn(void, { voidptr }),
	R3D_DisableSkybox = fn(void, {}),
	R3D_SetSkyboxRotation = fn(void, { float, float, float }),
	R3D_SetSkyboxIntensity = fn(void, { float, float, float }),

	R3D_SetBackgroundColor = fn(void, { float, float, float, float }),
	R3D_SetAmbientColor = fn(void, { float, float, float, float }),
	R3D_SetAmbientEnergy = fn(void, { float }),
	R3D_SetSSAO = fn(void, { bool }),
	R3D_SetSSAORadius = fn(void, { float }),
	R3D_SetSSAOBias = fn(void, { float }),
	R3D_SetSSAOIntensity = fn(void, { float }),
	R3D_SetBloomMode = fn(void, { int }),
	R3D_SetBloomIntensity = fn(void, { float }),
	R3D_SetBloomThreshold = fn(void, { float }),
	R3D_SetSSR = fn(void, { bool }),
	R3D_SetFogMode = fn(void, { int }),
	R3D_SetFogColor = fn(void, { float, float, float, float }),
	R3D_SetFogStart = fn(void, { float }),
	R3D_SetFogEnd = fn(void, { float }),
	R3D_SetFogDensity = fn(void, { float }),
	R3D_SetDofMode = fn(void, { int }),
	R3D_SetDofFocusPoint = fn(void, { float }),
	R3D_SetDofFocusScale = fn(void, { float }),
	R3D_SetTonemapMode = fn(void, { int }),
	R3D_SetTonemapExposure = fn(void, { float }),
	R3D_SetBrightness = fn(void, { float }),
	R3D_SetContrast = fn(void, { float }),
	R3D_SetSaturation = fn(void, { float }),
}

print(zune.fs.stat("./bin/r3d.dll"))
print(zune.fs.stat("./r3d/bin/r3d.dll"))
print(zune.fs.stat("./external/r3d/bin/r3d.dll"))
print(zune.fs.stat("./src/external/r3d/bin/r3d.dll"))

local lib = ffi.dlopen("./bin/r3d.dll", {}) :: {
	GetSymbol: (self: FFILibrary, symbol: string) -> FFIPointer?,
} & R3DFns

--[[
lib.R3D_FLAG_NONE = 0
lib.R3D_FLAG_FXAA = (1 << 0)
lib.R3D_FLAG_BLIT_LINEAR = (1 << 1)

lib.R3D_BLEND_OPAQUE = 0
lib.R3D_BLEND_ALPHA = 1
lib.R3D_BLEND_ADDITIVE = 2

lib.R3D_CULL_NONE = 0
lib.R3D_CULL_BACK = 1
lib.R3D_CULL_FRONT = 2

lib.R3D_LIGHT_DIR = 0
lib.R3D_LIGHT_SPOT = 1
lib.R3D_LIGHT_OMNI = 2

lib.R3D_BLOOM_DISABLED = 0
lib.R3D_BLOOM_MIX = 1
lib.R3D_BLOOM_ADDITIVE = 2

lib.R3D_FOG_DISABLED = 0
lib.R3D_FOG_LINEAR = 1
lib.R3D_FOG_EXP2 = 2
lib.R3D_FOG_EXP = 3

lib.R3D_TONEMAP_LINEAR = 0
lib.R3D_TONEMAP_REINHARD = 1
lib.R3D_TONEMAP_FILMIC = 2
lib.R3D_TONEMAP_ACES = 3
--]]
return lib
