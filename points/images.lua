------------------------------------------------------------------
----- All credit to atom0s for providing texture loading code ----
------------------------------------------------------------------
require 'common';
local ffi     = require('ffi');
local d3d     = require('d3d8');
local C       = ffi.C;
local d3d8dev = d3d.get_device();

ffi.cdef [[
    // Exported from Addons.dll
    HRESULT __stdcall D3DXCreateTextureFromFileA(IDirect3DDevice8* pDevice, const char* pSrcFile, IDirect3DTexture8** ppTexture);
]];

local images = {}

images.loadTextures = function(theme)
    if (theme == nil or theme == "") then
        theme = "default";
    end

    local textures = T {}
    -- Load the texture for usage..
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local res = C.D3DXCreateTextureFromFileA(d3d8dev, string.format('%s/themes/%s/ffxi-jobicons.png', addon.path, theme),
        texture_ptr);
    if (res ~= C.S_OK) then
        error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d.get_error(res)));
    end;
    textures.jobicons = d3d.gc_safe_release(ffi.new('IDirect3DTexture8*', texture_ptr[0]));

    return textures;
end

images.loadTextureFromItem = function(itemId)
    local item = AshitaCore:GetResourceManager():GetItemById(itemId);
    if itemId == nil then
        error("Bad item id");
    end
    ---@cast item -?

    local texPtr = ffi.new('IDirect3DTexture8*[1]');
    local res = C.D3DXCreateTextureFromFileInMemoryEx(
        d3d8.get_device(),
        item.Bitmap,
        item.ImageSize,
        C.D3DX_DEFAULT,
        C.D3DX_DEFAULT,
        1,
        0,
        C.D3DFMT_A8R8G8B8,
        C.D3DPOOL_MANAGED,
        C.D3DX_DEFAULT,
        C.D3DX_DEFAULT,
        0xFF000000,
        nil,
        nil,
        texPtr
    );
    if res ~= C.S_OK then
        error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d.get_error(res)));
    end
    return d3d8.gc_safe_release(ffi.new("IDirect3DTexture8*", texPtr[0]));
end

return images;
