-- this skybox script is made by Zalthen from Luanos engine (thank you)
-- also a bit modified
local rl = require("@raylib")

local ffi = zune.ffi
local mem = zune.mem

local structs = rl.structs
local lib = rl.lib
local const = rl.const

local skybox = {}
skybox._loaded = false

local function loadMaterialOnModel(model, texture, const)
	local materials = zune.ffi.ptrFromAddress(zune.mem.slice(model, structs.Model:offset("materials"), 8))

	-- Set texture
	local maps = materials:readptr(structs.Material:offset("maps"))
	maps:write(const or 0, texture, 0, structs.Texture:size())
end

function skybox.Load()
	assert(not skybox._loaded, "attempted to load skybox after already loading it")
	print("Loading skybox...")

	skybox.Mesh = lib.GenMeshCube(1, 1, 1)
	skybox.Model = lib.LoadModelFromMesh(skybox.Mesh)
	skybox.Image = lib.LoadImage("./src/assets/sky/default/cubemap.png")
	skybox.CubeMap = lib.LoadTextureCubemap(skybox.Image, const.CubemapLayout.CUBEMAP_LAYOUT_AUTO_DETECT)

	loadMaterialOnModel(skybox.Model, skybox.CubeMap, const.MaterialMapIndex.MATERIAL_MAP_CUBEMAP)

	skybox._loaded = true
	print("Loaded skybox!")
end

function skybox.Unload()
	assert(skybox._loaded, "attempted to unload skybox after already unloading it")
	print("Unloading skybox...")

	skybox._loaded = false

	skybox.Mesh = nil
	skybox.Model = nil
	skybox.Image = nil
	skybox.CubeMap = nil

	print("Unloaded skybox!")
end

function skybox.Draw(position)
	assert(skybox._loaded, "attempted to draw skybox before loading skybox")

	lib.rlDisableBackfaceCulling()
	lib.rlDisableDepthMask()

	lib.DrawModel(skybox.Model, position, 1, const.WHITE)

	lib.rlEnableBackfaceCulling()
	lib.rlEnableDepthMask()
end

return skybox
