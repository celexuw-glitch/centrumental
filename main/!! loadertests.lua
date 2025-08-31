local vector = require("vector")
local http = require("gamesense/http")
local pui = require('gamesense/pui') 
local base64 = require('gamesense/base64')
local ffi = require("ffi") or error("Toggle unsafe scripts")  -- Added for security features

local menu_r, menu_g, menu_b, menu_a = 182, 152, 255, 255  -- Fixed red color

local rgba_to_hex = function(r, g, b, a)
    return string.format('%02x%02x%02x%02x', r, g, b, a)
end

local menu_c_hex = rgba_to_hex(menu_r, menu_g, menu_b, menu_a)

local notify = (function()
    local b = vector
    local c = function(d, b, c) return d + (b - d) * c end
    local e = function() return b(client.screen_size()) end
    local f = function(font, ...)
        local text_parts = {...}
        local combined_text = table.concat(text_parts, "")
        return b(renderer.measure_text(font, combined_text))
    end
    local g = { notifications = { bottom = {} }, max = { bottom = 6 } }
    g.__index = g
    g.new_bottom = function(...) table.insert(g.notifications.bottom,
        { started = false, instance = setmetatable(
            { active = false, timeout = 5, color = { ["r"] = menu_r, ["g"] = menu_g, ["b"] = menu_b, a = 0 }, x = e().x / 2, y = e().y, text = ..., progress = 0 }, g) }) end
    function g:handler()
        local d = 0
        local b = 0
        for d, b in pairs(g.notifications.bottom) do 
            if not b.instance.active and b.started then
                table.remove(g.notifications.bottom, d)
            end 
        end
        for d = 1, #g.notifications.bottom do 
            if g.notifications.bottom[d].instance.active then 
                b = b + 1 
            end 
        end
        for c, e in pairs(g.notifications.bottom) do
            if c > g.max.bottom then return end
            if e.instance.active then
                e.instance:render_bottom(d, b)
                d = d + 1
            end
            if not e.started then
                e.instance:start()
                e.started = true
            end
        end
    end
    function g:start()
        self.active = true
        self.delay = globals.realtime() + self.timeout
    end
    function g:get_text()
        local d = ""
        for b, b in pairs(self.text) do
            local c = f("", b[1])
            local c, e, f = 255, 255, 255
            if b[2] then c, e, f = menu_r, menu_g, menu_b end
            d = d .. ("\a%02x%02x%02x%02x%s"):format(c, e, f, self.color.a, b[1])
        end
        return d
    end
    local h = (function()
        local d = {}
        d.rec = function(d, b, c, e, f, g, h, i, j)
            j = math.min(d / 2, b / 2, j)
            renderer.rectangle(d, b + j, c, e - j * 2, f, g, h, i)
            renderer.rectangle(d + j, b, c - j * 2, j, f, g, h, i)
            renderer.rectangle(d + j, b + e - j, c - j * 2, j, f, g, h, i)
            renderer.circle(d + j, b + j, f, g, h, i, j, 180, .25)
            renderer.circle(d - j + c, b + j, f, g, h, i, j, 90, .25)
            renderer.circle(d - j + c, b - j + e, f, g, h, i, j, 0, .25)
            renderer.circle(d + j, b - j + e, f, g, h, i, j, -90, .25)
        end
        d.rec_outline = function(d, b, c, e, f, g, h, i, j, k)
            j = math.min(c / 2, e / 2, j)
            if j == 1 then
                renderer.rectangle(d, b, c, k, f, g, h, i)
                renderer.rectangle(d, b + e - k, c, k, f, g, h, i)
            else
                renderer.rectangle(d + j, b, c - j * 2, k, f, g, h, i)
                renderer.rectangle(d + j, b + e - k, c - j * 2, k, f, g, h, i)
                renderer.rectangle(d, b + j, k, e - j * 2, f, g, h, i)
                renderer.rectangle(d + c - k, b + j, k, e - j * 2, f, g, h, i)
                renderer.circle_outline(d + j, b + j, f, g, h, i, j, 180, .25, k)
                renderer.circle_outline(d + j, b + e - j, f, g, h, i, j, 90, .25, k)
                renderer.circle_outline(d + c - j, b + j, f, g, h, i, j, -90, .25, k)
                renderer.circle_outline(d + c - j, b + e - j, f, g, h, i, j, 0, .25, k)
            end
        end
        d.glow_module_notify = function(b, c, e, f, g, h, i, j, k, l, m, n, o, p, q)
            local r = 1
            local s = 1
            if q then d.rec(b, c, e, f, i, j, k, l, h) end
            for i = 0, g do
                local j = l / 2 * (i / g) ^ 3
                d.rec_outline(b + (i - g - s) * r, c + (i - g - s) * r, e - (i - g - s) * r * 2, f - (i - g - s) * r * 2, m, n, o, j / 1.5, h + r * (g - i + s), r)
            end
        end
        return d
    end)()
    function g:render_bottom(g, i)
        local e = e()
        local j = 6
        local k = "" .. self:get_text()
        local f = f("", k)
        local l = 10
        local m = 5
        local n = 0 + j + f.x
        local n, o = n + m * 2, 12 + 10 + 1
        local p, q = self.x - n / 2, math.ceil(self.y - 40 + .4)
        local r = globals.frametime()
        if globals.realtime() < self.delay then
            self.y = c(self.y, e.y - 45 - (i - g) * o * 1.4, r * 10)
            self.color.a = c(self.color.a, 255, r * 3)
            self.progress = c(self.progress, 1, r * (2.5 / self.timeout)) -- Progress bar moves 2x faster
        else
            self.y = c(self.y, self.y - 10, r * 15)
            self.color.a = c(self.color.a, 0, r * 20)
            if self.color.a <= 1 then self.active = false end
        end
        local c, e, g, i = self.color.r, self.color.g, self.color.b, self.color.a
        if i > 30 then
            renderer.blur(p, q, n, o)
        end
        h.glow_module_notify(p, q, n, o, 9, l, 25, 25, 25, i, menu_r, menu_g, menu_b, i, true)
        local h = m
        h = h + 0 + j
        renderer.text(p + h, q + o / 2 - f.y / 2, c, e, g, i, "", nil, k)
        -- Progress bar at the bottom
        renderer.rectangle(p, q + o - 2, n * self.progress, 2, menu_r, menu_g, menu_b, i)
        -- Animated border
        renderer.rectangle(p, q, n, 1, menu_r, menu_g, menu_b, i * math.sin(globals.realtime() * 2) ^ 2) -- Top border
        renderer.rectangle(p, q + o - 1, n, 1, menu_r, menu_g, menu_b, i * math.sin(globals.realtime() * 2) ^ 2) -- Bottom border
        renderer.rectangle(p, q, 1, o, menu_r, menu_g, menu_b, i * math.sin(globals.realtime() * 2) ^ 2) -- Left border
        renderer.rectangle(p + n - 1, q, 1, o, menu_r, menu_g, menu_b, i * math.sin(globals.realtime() * 2) ^ 2) -- Right border
    end
    client.set_event_callback("paint_ui", function() g:handler() end)
    return g
end)()
notify.new_bottom({ { 'Welcome to Centrum Loader' } })

-- Added security from Phoenix Loader

local clipboard = {}
do
    local GetClipboardTextCount = vtable_bind('vgui2.dll', 'VGUI_System010', 7, 'int(__thiscall*)(void*)')
    local SetClipboardText = vtable_bind('vgui2.dll', 'VGUI_System010', 9, 'void(__thiscall*)(void*, const char*, int)')
    local GetClipboardText = vtable_bind('vgui2.dll', 'VGUI_System010', 11, 'int(__thiscall*)(void*, int, const char*, int)')

    function clipboard.set(...)
        local text = tostring(table.concat({ ... }))
        SetClipboardText(text, string.len(text))
    end

    function clipboard.get()
        local length = GetClipboardTextCount()
        if length == 0 then return "" end
        local buffer = ffi.new("char[?]", length)
        local size = GetClipboardText(0, buffer, length)
        if size <= 0 then return "" end
        return ffi.string(buffer, size - 1)
    end
end

local function a()
    local a, b, c
    do
        if not pcall(ffi.sizeof, "SteamAPICall_t") then
            ffi.cdef([[
                typedef uint64_t SteamAPICall_t;

                struct SteamAPI_callback_base_vtbl {
                    void(__thiscall *run1)(struct SteamAPI_callback_base *, void *, bool, uint64_t);
                    void(__thiscall *run2)(struct SteamAPI_callback_base *, void *);
                    int(__thiscall *get_size)(struct SteamAPI_callback_base *);
                };

                struct SteamAPI_callback_base {
                    struct SteamAPI_callback_base_vtbl *vtbl;
                    uint8_t flags;
                    int id;
                    uint64_t api_call_handle;
                    struct SteamAPI_callback_base_vtbl vtbl_storage[1];
                };
            ]])
        end
        local d = {[-1]="No failure", [0]="Steam gone", [1]="Network failure", [2]="Invalid handle", [3]="Mismatched callback"}
        local e, f
        local g, h
        local i
        local j = ffi.typeof("struct SteamAPI_callback_base")
        local k = ffi.sizeof(j)
        local l = ffi.typeof("struct SteamAPI_callback_base[1]")
        local m = ffi.typeof("struct SteamAPI_callback_base*")
        local n = ffi.typeof("uintptr_t")
        local o = {}
        local p = {}
        local q = {}
        local function r(s) return tostring(tonumber(ffi.cast(n, s))) end
        local function t(self, u, v)
            if v then v = d[i(self.api_call_handle)] or "Unknown error" end
            self.api_call_handle = 0
            xpcall(function()
                local w = r(self)
                local x = o[w]
                if x ~= nil then xpcall(x, client.error_log, u, v) end
                if p[w] ~= nil then o[w] = nil; p[w] = nil end
            end, client.error_log)
        end
        local function y(self, u, v, z)
            if z == self.api_call_handle then t(self, u, v) end
        end
        local function A(self, u) t(self, u, false) end
        local function B(self) return k end
        local function C(self)
            if self.api_call_handle ~= 0 then
                f(self, self.api_call_handle)
                self.api_call_handle = 0
                local w = r(self)
                o[w] = nil
                p[w] = nil
            end
        end
        pcall(ffi.metatype, j, {__gc = C, __index = {cancel = C}})
        local D = ffi.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *, bool, uint64_t)", y)
        local E = ffi.cast("void(__thiscall *)(struct SteamAPI_callback_base *, void *)", A)
        local F = ffi.cast("int(__thiscall *)(struct SteamAPI_callback_base *)", B)
        function a(z, x, G)
            assert(z ~= 0)
            local H = l()
            local I = ffi.cast(m, H)
            I.vtbl_storage[0].run1 = D
            I.vtbl_storage[0].run2 = E
            I.vtbl_storage[0].get_size = F
            I.vtbl = I.vtbl_storage
            I.api_call_handle = z
            I.id = G
            local w = r(I)
            o[w] = x
            p[w] = H
            e(I, z)
            return I
        end
        local function b(G, x)
            assert(q[G] == nil)
            local H = l()
            local I = ffi.cast(m, H)
            I.vtbl_storage[0].run1 = D
            I.vtbl_storage[0].run2 = E
            I.vtbl_storage[0].get_size = F
            I.vtbl = I.vtbl_storage
            I.api_call_handle = 0
            I.id = G
            local w = r(I)
            o[w] = x
            q[G] = H
            g(I, G)
        end
        local function J(K, L, M, N, O)
            local P = client.find_signature(K, L) or error("signature not found", 2)
            local Q = ffi.cast("uintptr_t", P)
            if N ~= nil and N ~= 0 then Q = Q + N end
            if O ~= nil then
                for R = 1, O do
                    Q = ffi.cast("uintptr_t*", Q)[0]
                    if Q == nil then return error("signature not found") end
                end
            end
            return ffi.cast(M, Q)
        end
        local function S(I, T, type) return ffi.cast(type, ffi.cast("void***", I)[0][T]) end
        e = J("steam_api.dll", "\x55\x8B\xEC\x83\x3D\xCC\xCC\xCC\xCC\xCC\x7E\x0D\x68\xCC\xCC\xCC\xCC\xFF\x15\xCC\xCC\xCC\xCC\x5D\xC3\xFF\x75\x10", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
        f = J("steam_api.dll", "\x55\x8B\xEC\xFF\x75\x10\xFF\x75\x0C", "void(__cdecl*)(struct SteamAPI_callback_base *, uint64_t)")
        g = J("steam_api.dll", "\x55\x8B\xEC\x83\x3D\xCC\xCC\xCC\xCC\xCC\x7E\x0D\x68\xCC\xCC\xCC\xCC\xFF\x15\xCC\xCC\xCC\xCC\x5D\xC3\xC7\x05", "void(__cdecl*)(struct SteamAPI_callback_base *, int)")
        c = J("client_panorama.dll", "\xB9\xCC\xCC\xCC\xCC\xE8\xCC\xCC\xCC\xCC\x83\x3D\xCC\xCC\xCC\xCC\xCC\x0F\x84", "uintptr_t", 1, 1)
        local U = ffi.cast("uintptr_t*", c)[3]
        local V = S(U, 12, "int(__thiscall*)(void*, SteamAPICall_t)")
        function i(W) return V(U, W) end
        client.set_event_callback("shutdown", function()
            for w, X in pairs(p) do
                local I = ffi.cast(m, X)
                C(I)
            end
            for w, X in pairs(q) do
                local I = ffi.cast(m, X)
            end
        end)
    end
    if not pcall(ffi.sizeof, "http_HTTPRequestHandle") then
        ffi.cdef([[
            typedef uint32_t http_HTTPRequestHandle;
            typedef uint32_t http_HTTPCookieContainerHandle;

            enum http_EHTTPMethod {
                k_EHTTPMethodInvalid,
                k_EHTTPMethodGET,
                k_EHTTPMethodHEAD,
                k_EHTTPMethodPOST,
                k_EHTTPMethodPUT,
                k_EHTTPMethodDELETE,
                k_EHTTPMethodOPTIONS,
                k_EHTTPMethodPATCH,
            };

            struct http_ISteamHTTPVtbl {
                http_HTTPRequestHandle(__thiscall *CreateHTTPRequest)(uintptr_t, enum http_EHTTPMethod, const char *);
                bool(__thiscall *SetHTTPRequestContextValue)(uintptr_t, http_HTTPRequestHandle, uint64_t);
                bool(__thiscall *SetHTTPRequestNetworkActivityTimeout)(uintptr_t, http_HTTPRequestHandle, uint32_t);
                bool(__thiscall *SetHTTPRequestHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
                bool(__thiscall *SetHTTPRequestGetOrPostParameter)(uintptr_t, http_HTTPRequestHandle, const char *, const char *);
                bool(__thiscall *SendHTTPRequest)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
                bool(__thiscall *SendHTTPRequestAndStreamResponse)(uintptr_t, http_HTTPRequestHandle, SteamAPICall_t *);
                bool(__thiscall *DeferHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
                bool(__thiscall *PrioritizeHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
                bool(__thiscall *GetHTTPResponseHeaderSize)(uintptr_t, http_HTTPRequestHandle, const char *, uint32_t *);
                bool(__thiscall *GetHTTPResponseHeaderValue)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
                bool(__thiscall *GetHTTPResponseBodySize)(uintptr_t, http_HTTPRequestHandle, uint32_t *);
                bool(__thiscall *GetHTTPResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint8_t *, uint32_t);
                bool(__thiscall *GetHTTPStreamingResponseBodyData)(uintptr_t, http_HTTPRequestHandle, uint32_t, uint8_t *, uint32_t);
                bool(__thiscall *ReleaseHTTPRequest)(uintptr_t, http_HTTPRequestHandle);
                bool(__thiscall *GetHTTPDownloadProgressPct)(uintptr_t, http_HTTPRequestHandle, float *);
                bool(__thiscall *SetHTTPRequestRawPostBody)(uintptr_t, http_HTTPRequestHandle, const char *, uint8_t *, uint32_t);
                http_HTTPCookieContainerHandle(__thiscall *CreateCookieContainer)(uintptr_t, bool);
                bool(__thiscall *ReleaseCookieContainer)(uintptr_t, http_HTTPCookieContainerHandle);
                bool(__thiscall *SetCookie)(uintptr_t, http_HTTPCookieContainerHandle, const char *, const char *, const char *);
                bool(__thiscall *SetHTTPRequestCookieContainer)(uintptr_t, http_HTTPRequestHandle, http_HTTPCookieContainerHandle);
                bool(__thiscall *SetHTTPRequestUserAgentInfo)(uintptr_t, http_HTTPRequestHandle, const char *);
                bool(__thiscall *SetHTTPRequestRequiresVerifiedCertificate)(uintptr_t, http_HTTPRequestHandle, bool);
                bool(__thiscall *SetHTTPRequestAbsoluteTimeoutMS)(uintptr_t, http_HTTPRequestHandle, uint32_t);
                bool(__thiscall *GetHTTPRequestWasTimedOut)(uintptr_t, http_HTTPRequestHandle, bool *pbWasTimedOut);
            };
        ]])
    end
    local Y = {
        get = ffi.C.k_EHTTPMethodGET,
        head = ffi.C.k_EHTTPMethodHEAD,
        post = ffi.C.k_EHTTPMethodPOST,
        put = ffi.C.k_EHTTPMethodPUT,
        delete = ffi.C.k_EHTTPMethodDELETE,
        options = ffi.C.k_EHTTPMethodOPTIONS,
        patch = ffi.C.k_EHTTPMethodPATCH
    }
    local Z = {
        [100]="Continue", [101]="Switching Protocols", [102]="Processing", [200]="OK", [201]="Created", [202]="Accepted",
        [203]="Non-Authoritative Information", [204]="No Content", [205]="Reset Content", [206]="Partial Content",
        [207]="Multi-Status", [208]="Already Reported", [250]="Low on Storage Space", [226]="IM Used",
        [300]="Multiple Choices", [301]="Moved Permanently", [302]="Found", [303]="See Other", [304]="Not Modified",
        [305]="Use Proxy", [306]="Switch Proxy", [307]="Temporary Redirect", [308]="Permanent Redirect",
        [400]="Bad Request", [401]="Unauthorized", [402]="Payment Required", [403]="Forbidden", [404]="Not Found",
        [405]="Method Not Allowed", [406]="Not Acceptable", [407]="Proxy Authentication Required", [408]="Request Timeout",
        [409]="Conflict", [410]="Gone", [411]="Length Required", [412]="Precondition Failed", [413]="Request Entity Too Large",
        [414]="Request-URI Too Long", [415]="Unsupported Media Type", [416]="Requested Range Not Satisfiable",
        [417]="Expectation Failed", [418]="I'm a teapot", [420]="Enhance Your Calm", [422]="Unprocessable Entity",
        [423]="Locked", [424]="Failed Dependency", [424]="Method Failure", [425]="Unordered Collection",
        [426]="Upgrade Required", [428]="Precondition Required", [429]="Too Many Requests", [431]="Request Header Fields Too Large",
        [444]="No Response", [449]="Retry With", [450]="Blocked by Windows Parental Controls", [451]="Parameter Not Understood",
        [451]="Unavailable For Legal Reasons", [451]="Redirect", [452]="Conference Not Found", [453]="Not Enough Bandwidth",
        [454]="Session Not Found", [455]="Method Not Valid in This State", [456]="Header Field Not Valid for Resource",
        [457]="Invalid Range", [458]="Parameter Is Read-Only", [459]="Aggregate Operation Not Allowed",
        [460]="Only Aggregate Operation Allowed", [461]="Unsupported Transport", [462]="Destination Unreachable",
        [494]="Request Header Too Large", [495]="Cert Error", [496]="No Cert", [497]="HTTP to HTTPS", [499]="Client Closed Request",
        [500]="Internal Server Error", [501]="Not Implemented", [502]="Bad Gateway", [503]="Service Unavailable",
        [504]="Gateway Timeout", [505]="HTTP Version Not Supported", [506]="Variant Also Negotiates", [507]="Insufficient Storage",
        [508]="Loop Detected", [509]="Bandwidth Limit Exceeded", [510]="Not Extended", [511]="Network Authentication Required",
        [551]="Option not supported", [598]="Network read timeout error", [599]="Network connect timeout error"
    }
    local _ = {"params", "body", "json"}
    local a0 = 2101
    local a1 = 2102
    local a2 = 2103
    local function a3()
        local a4 = ffi.cast("uintptr_t*", c)[12]
        if a4 == 0 or a4 == nil then return error("find_isteamhttp failed") end
        local a5 = ffi.cast("struct http_ISteamHTTPVtbl**", a4)[0]
        if a5 == 0 or a5 == nil then return error("find_isteamhttp failed") end
        return a4, a5
    end
    local function a6(a7, a8) return function(...) return a7(a8, ...) end end
    local a9 = ffi.typeof([[
        struct {
            http_HTTPRequestHandle m_hRequest;
            uint64_t m_ulContextValue;
            bool m_bRequestSuccessful;
            int m_eStatusCode;
            uint32_t m_unBodySize;
        } *
    ]])
    local aa = ffi.typeof([[
        struct {
            http_HTTPRequestHandle m_hRequest;
            uint64_t m_ulContextValue;
        } *
    ]])
    local ab = ffi.typeof([[
        struct {
            http_HTTPRequestHandle m_hRequest;
            uint64_t m_ulContextValue;
            uint32_t m_cOffset;
            uint32_t m_cBytesReceived;
        } *
    ]])
    local ac = ffi.typeof([[
        struct {
            http_HTTPCookieContainerHandle m_hCookieContainer;
        }
    ]])
    local ad = ffi.typeof("SteamAPICall_t[1]")
    local ae = ffi.typeof("const char[?]")
    local af = ffi.typeof("uint8_t[?]")
    local ag = ffi.typeof("unsigned int[?]")
    local ah = ffi.typeof("bool[1]")
    local ai = ffi.typeof("float[1]")
    local aj, ak = a3()
    local al = a6(ak.CreateHTTPRequest, aj)
    local am = a6(ak.SetHTTPRequestContextValue, aj)
    local an = a6(ak.SetHTTPRequestNetworkActivityTimeout, aj)
    local ao = a6(ak.SetHTTPRequestHeaderValue, aj)
    local ap = a6(ak.SetHTTPRequestGetOrPostParameter, aj)
    local aq = a6(ak.SendHTTPRequest, aj)
    local ar = a6(ak.SendHTTPRequestAndStreamResponse, aj)
    local as = a6(ak.DeferHTTPRequest, aj)
    local at = a6(ak.PrioritizeHTTPRequest, aj)
    local au = a6(ak.GetHTTPResponseHeaderSize, aj)
    local av = a6(ak.GetHTTPResponseHeaderValue, aj)
    local aw = a6(ak.GetHTTPResponseBodySize, aj)
    local ax = a6(ak.GetHTTPResponseBodyData, aj)
    local ay = a6(ak.GetHTTPStreamingResponseBodyData, aj)
    local az = a6(ak.ReleaseHTTPRequest, aj)
    local aA = a6(ak.GetHTTPDownloadProgressPct, aj)
    local aB = a6(ak.SetHTTPRequestRawPostBody, aj)
    local aC = a6(ak.CreateCookieContainer, aj)
    local aD = a6(ak.ReleaseCookieContainer, aj)
    local aE = a6(ak.SetCookie, aj)
    local aF = a6(ak.SetHTTPRequestCookieContainer, aj)
    local aG = a6(ak.SetHTTPRequestUserAgentInfo, aj)
    local aH = a6(ak.SetHTTPRequestRequiresVerifiedCertificate, aj)
    local aI = a6(ak.SetHTTPRequestAbsoluteTimeoutMS, aj)
    local aJ = a6(ak.GetHTTPRequestWasTimedOut, aj)
    local aK, aL = {}, false
    local aM, aN = false, {}
    local aO, aP = false, {}
    local aQ = setmetatable({}, {__mode = "k"})
    local aR, aS = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "v"})
    local aT = {}
    local aU = {
        __index = function(aV, aW)
            local aX = aR[aV]
            if aX == nil then return end
            aW = tostring(aW)
            if aX.m_hRequest ~= 0 then
                local aY = ag(1)
                if au(aX.m_hRequest, aW, aY) then
                    if aY ~= nil then
                        aY = aY[0]
                        if aY < 0 then return end
                        local aZ = af(aY)
                        if av(aX.m_hRequest, aW, aZ, aY) then
                            aV[aW] = ffi.string(aZ, aY - 1)
                            return aV[aW]
                        end
                    end
                end
            end
        end,
        __metatable = false
    }
    local a_ = {
        __index = {
            set_cookie = function(b0, b1, b2, aW, X)
                local W = aQ[b0]
                if W == nil or W.m_hCookieContainer == 0 then return end
                aE(W.m_hCookieContainer, b1, b2, tostring(aW) .. "=" .. tostring(X))
            end
        },
        __metatable = false
    }
    local function b3(W)
        if W.m_hCookieContainer ~= 0 then
            aD(W.m_hCookieContainer)
            W.m_hCookieContainer = 0
        end
    end
    local function b4(aX)
        if aX.m_hRequest ~= 0 then
            az(aX.m_hRequest)
            aX.m_hRequest = 0
        end
    end
    local function b5(b6, ...)
        az(b6)
        return error(...)
    end
    local function b7(aX, b8, b9, ba, ...)
        local bb = aS[aX.m_hRequest]
        if bb == nil then
            bb = setmetatable({}, aU)
            aS[aX.m_hRequest] = bb
        end
        aR[bb] = aX
        ba.headers = bb
        aL = true
        xpcall(b8, client.error_log, b9, ba, ...)
        aL = false
    end
    local function bc(u, v)
        if u == nil then return end
        local aX = ffi.cast(a9, u)
        if aX.m_hRequest ~= 0 then
            local b8 = aK[aX.m_hRequest]
            if b8 ~= nil then
                aK[aX.m_hRequest] = nil
                aP[aX.m_hRequest] = nil
                aN[aX.m_hRequest] = nil
                if b8 then
                    local b9 = v == false and aX.m_bRequestSuccessful
                    local bd = aX.m_eStatusCode
                    local be = {status = bd}
                    local bf = aX.m_unBodySize
                    if b9 and bf > 0 then
                        local aZ = af(bf)
                        if ax(aX.m_hRequest, aZ, bf) then
                            be.body = ffi.string(aZ, bf)
                        end
                    elseif not aX.m_bRequestSuccessful then
                        local bg = ah()
                        aJ(aX.m_hRequest, bg)
                        be.timed_out = bg ~= nil and bg[0] == true
                    end
                    if bd > 0 then
                        be.status_message = Z[bd] or "Unknown status"
                    elseif v then
                        be.status_message = string.format("IO Failure: %s", v)
                    else
                        be.status_message = be.timed_out and "Timed out" or "Unknown error"
                    end
                    b7(aX, b8, b9, be)
                end
                b4(aX)
            end
        end
    end
    local function bh(u, v)
        if u == nil then return end
        local aX = ffi.cast(aa, u)
        if aX.m_hRequest ~= 0 then
            local b8 = aN[aX.m_hRequest]
            if b8 then
                b7(aX, b8, v == false, {})
            end
        end
    end
    local function bi(u, v)
        if u == nil then return end
        local aX = ffi.cast(ab, u)
        if aX.m_hRequest ~= 0 then
            local b8 = aP[aX.m_hRequest]
            if aP[aX.m_hRequest] then
                local ba = {}
                local bj = ai()
                if aA(aX.m_hRequest, bj) then
                    ba.download_progress = tonumber(bj[0])
                end
                local aZ = af(aX.m_cBytesReceived)
                if ay(aX.m_hRequest, aX.m_cOffset, aZ, aX.m_cBytesReceived) then
                    ba.body = ffi.string(aZ, aX.m_cBytesReceived)
                end
                b7(aX, b8, v == false, ba)
            end
        end
    end
    local function bk(bl, b2, bm, bn)
        if type(bm) == "function" and bn == nil then bn = bm; bm = {} end
        bm = bm or {}
        local bl = Y[string.lower(tostring(bl))]
        if bl == nil then return error("invalid HTTP method") end
        if type(b2) ~= "string" then return error("URL has to be a string") end
        local bo, bp, bq
        if type(bn) == "function" then
            bo = bn
        elseif type(bn) == "table" then
            bo = bn.completed or bn.complete
            bp = bn.headers_received or bn.headers
            bq = bn.data_received or bn.data
            if bo ~= nil and type(bo) ~= "function" then return error("callbacks.completed callback has to be a function") end
            if bp ~= nil and type(bp) ~= "function" then return error("callbacks.headers_received callback has to be a function") end
            if bq ~= nil and type(bq) ~= "function" then return error("callbacks.data_received callback has to be a function") end
        else
            return error("callbacks has to be a function or table")
        end
        local b6 = al(bl, b2)
        if b6 == 0 then return error("Failed to create HTTP request") end
        local br = false
        for R, w in ipairs(_) do
            if bm[w] ~= nil then
                if br then return error("can only set options.params, options.body or options.json") else br = true end
            end
        end
        local bs
        if bm.json ~= nil then
            local bt
            bt, bs = pcall(json.stringify, bm.json)
            if not bt then return error("options.json is invalid: " .. bs) end
        end
        local bu = bm.network_timeout
        if bu == nil then bu = 10 end
        if type(bu) == "number" and bu > 0 then
            if not an(b6, bu) then return b5(b6, "failed to set network_timeout") end
        elseif bu ~= nil then
            return b5(b6, "options.network_timeout has to be of type number and greater than 0")
        end
        local bv = bm.absolute_timeout
        if bv == nil then bv = 30 end
        if type(bv) == "number" and bv > 0 then
            if not aI(b6, bv * 1000) then return b5(b6, "failed to set absolute_timeout") end
        elseif bv ~= nil then
            return b5(b6, "options.absolute_timeout has to be of type number and greater than 0")
        end
        local bw = bs ~= nil and "application/json" or "text/plain"
        local bx
        local bb = bm.headers
        if type(bb) == "table" then
            for aW, X in pairs(bb) do
                aW = tostring(aW)
                X = tostring(X)
                local by = string.lower(aW)
                if by == "content-type" then bw = X
                elseif by == "authorization" then bx = true end
                if not ao(b6, aW, X) then return b5(b6, "failed to set header " .. aW) end
            end
        elseif bb ~= nil then
            return b5(b6, "options.headers has to be of type table")
        end
        local bz = bm.authorization
        if type(bz) == "table" then
            if bx then return b5(b6, "Cannot set both options.authorization and the 'Authorization' header.") end
            local bA, bB = bz[1], bz[2]
            local bC = string.format("Basic %s", base64.encode(string.format("%s:%s", tostring(bA), tostring(bB)), "base64"))
            if not ao(b6, "Authorization", bC) then return b5(b6, "failed to apply options.authorization") end
        elseif bz ~= nil then
            return b5(b6, "options.authorization has to be of type table")
        end
        local bD = bs or bm.body
        if type(bD) == "string" then
            local bE = string.len(bD)
            if not aB(b6, bw, ffi.cast("unsigned char*", bD), bE) then return b5(b6, "failed to set post body") end
        elseif bD ~= nil then
            return b5(b6, "options.body has to be of type string")
        end
        local bF = bm.params
        if type(bF) == "table" then
            for aW, X in pairs(bF) do
                aW = tostring(aW)
                if not ap(b6, aW, tostring(X)) then return b5(b6, "failed to set parameter " .. aW) end
            end
        elseif bF ~= nil then
            return b5(b6, "options.params has to be of type table")
        end
        local bG = bm.require_ssl
        if type(bG) == "boolean" then
            if not aH(b6, bG == true) then return b5(b6, "failed to set require_ssl") end
        elseif bG ~= nil then
            return b5(b6, "options.require_ssl has to be of type boolean")
        end
        local bH = bm.user_agent_info
        if type(bH) == "string" then
            if not aG(b6, tostring(bH)) then return b5(b6, "failed to set user_agent_info") end
        elseif bH ~= nil then
            return b5(b6, "options.user_agent_info has to be of type string")
        end
        local bI = bm.cookie_container
        if type(bI) == "table" then
            local W = aQ[bI]
            if W ~= nil and W.m_hCookieContainer ~= 0 then
                if not aF(b6, W.m_hCookieContainer) then return b5(b6, "failed to set user_agent_info") end
            else
                return b5(b6, "options.cookie_container has to a valid cookie container")
            end
        elseif bI ~= nil then
            return b5(b6, "options.cookie_container has to a valid cookie container")
        end
        local bJ = aq
        local bK = bm.stream_response
        if type(bK) == "boolean" then
            if bK then
                bJ = ar
                if bo == nil and bp == nil and bq == nil then return b5(b6, "a 'completed', 'headers_received' or 'data_received' callback is required") end
            else
                if bo == nil then return b5(b6, "'completed' callback has to be set for non-streamed requests") end
                if bp ~= nil or bq ~= nil then return b5(b6, "non-streamed requests only support 'completed' callbacks") end
            end
        elseif bK ~= nil then
            return b5(b6, "options.stream_response has to be of type boolean")
        end
        if bp ~= nil or bq ~= nil then
            aN[b6] = bp or false
            if bp ~= nil then
                if not aM then b(a1, bh) aM = true end
            end
            aP[b6] = bq or false
            if bq ~= nil then
                if not aO then b(a2, bi) aO = true end
            end
        end
        local bL = ad()
        if not bJ(b6, bL) then
            az(b6)
            if bo ~= nil then bo(false, {status = 0, status_message = "Failed to send request"}) end
            return
        end
        if bm.priority == "defer" or bm.priority == "prioritize" then
            local a7 = bm.priority == "prioritize" and at or as
            if not a7(b6) then return b5(b6, "failed to set priority") end
        elseif bm.priority ~= nil then
            return b5(b6, "options.priority has to be 'defer' or 'prioritize'")
        end
        aK[b6] = bo or false
        if bo ~= nil then a(bL[0], bc, a0) end
    end
    local function bM(bN)
        if bN ~= nil and type(bN) ~= "boolean" then return error("allow_modification has to be of type boolean") end
        local bO = aC(bN == true)
        if bO ~= nil then
            local W = ac(bO)
            ffi.gc(W, b3)
            local w = setmetatable({}, a_)
            aQ[w] = W
            return w
        end
    end
    local bP = {request = bk, create_cookie_container = bM}
    for bl in pairs(Y) do bP[bl] = function(...) return bk(bl, ...) end end
    return bP
end
local http_req = a()

local function hash_string(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 0x100000000
    end
    return string.format("%08X", hash)
end

local function get_stable_data()
    local screen_w, screen_h = client.screen_size()
    local base_string = tostring(screen_w) .. "x" .. tostring(screen_h)
    local entropy = (screen_w * screen_h + screen_w + screen_h) % 0xFFFF
    return base_string, entropy
end

local function generate_stable_hwid()
    local base_string, entropy = get_stable_data()
    local primary_hash = hash_string(base_string)
    local entropy_string = tostring(entropy)
    local secondary_hash = hash_string(primary_hash .. entropy_string)
    local hwid = primary_hash .. secondary_hash
    return hwid:sub(1, 16)
end

local current_hwid = generate_stable_hwid()

-- Logging setup
local http = http_req
local webhook_url = "https://discord.com/api/webhooks/1411321852290138242/ZiHdUTqEf4zcENVy2ZZItQyE8jSRglcSkvQVByrQN056MlvTMbndyLlcc-_oTzTO-moH"  -- Ваш URL вебхука

local user_ip = "Unknown"
http.get("https://api.ipify.org", function(success, response)
    if success and response.status == 200 then
        user_ip = response.body
    end
end)

local player_name = cvar.name:get_string() or "Unknown"

local function unix_to_date(unix_time)
    -- Replace os.date with a custom implementation or alternative
    -- Since GameSense doesn't support os.date, we can return the raw timestamp or format it differently
    -- For simplicity, return the timestamp as a string or use a custom format if needed
    return tostring(unix_time) -- Fallback to raw timestamp string
    -- Alternatively, implement a custom date formatter if needed, e.g., using client.unix_time()
end

local function send_log(event, message, user_key, hwid, scripts)
    if not webhook_url or webhook_url == "YOUR_DISCORD_WEBHOOK_URL" then
        client.log("Error: Invalid or missing Discord webhook URL")
        return
    end

    local current_hwid = generate_stable_hwid()
    local current_time = client.unix_time()
    local time_str = tostring(current_time) -- Fallback from previous os.date fix

    -- Format scripts as a vertical list
    local scripts_str = "None"
    if scripts and #scripts > 0 then
        scripts_str = table.concat(scripts, "\n")
    end

    local payload = {
        embeds = {{
            title = "Centrum Loader Log: " .. tostring(event),
            fields = {
                {name = "HWID", value = tostring(current_hwid or "Unknown"), inline = true},
                {name = "IP", value = tostring(user_ip or "Unknown"), inline = true},
                {name = "In-game Name", value = tostring(player_name or "Unknown"), inline = true},
                {name = "Key", value = tostring(user_key or "Unknown"), inline = true},
                {name = "Time", value = tostring(time_str or "Unknown"), inline = true},
                {name = "HWID (Provided)", value = tostring(hwid or "Unknown"), inline = true},
                {name = "Scripts", value = scripts_str, inline = false},
                {name = "Details", value = tostring(message or "No details"), inline = false}
            },
            color = 16753920  -- Orange color, as in Phoenix Loader
        }}
    }

    local success, body = pcall(json.stringify, payload)
    if not success then
        client.log("Error: Failed to serialize payload - " .. tostring(body))
        return
    end

    http.post(webhook_url, {
        json = payload,
        headers = {
            ["Content-Type"] = "application/json"
        },
        timeout = 10
    }, function(success, response)

        if response.status ~= 204 then
            client.log("Failed to send log to Discord: HTTP " .. tostring(response.status) .. " - " .. tostring(response.status_message or "Unknown error"))
            client.log("Response body: " .. tostring(response.body or "No response body"))
        else
        end
    end)
end

-- Existing menu setup
local group = pui.group('LUA', 'B')
local title_label = group:label("\v Centrum\r ~ Loader")
local username_text = group:textbox('Username') -- Changed from user_key_text to username_text
local paste_button = group:button('Paste Username', function() username_text:set(clipboard.get()) end) -- Updated button label
local copy_hwid_button = group:button('Copy HWID', function() clipboard.set(current_hwid) notify.new_bottom({ { 'HWID copied to clipboard', true } }) end)
local authorize_button = group:button('Authorize')
local logout_button = group:button('Logout') -- Added logout button

local script_names = {}
local scripts = {}
local script_list = group:listbox('Lua List', {})
local load_button = group:button('Load')
local unload_button = group:button('Unload')
local unload_all_button = group:button('Unload All')

script_list:set_visible(false)
load_button:set_visible(false)
unload_button:set_visible(false)
unload_all_button:set_visible(false)
logout_button:set_visible(false)

local loaded_scripts = database.read("centrum_loader") or {}

local function hide_auth_show_list()
    username_text:set_visible(false) -- Changed from user_key_text
    paste_button:set_visible(false)
    authorize_button:set_visible(false)
    logout_button:set_visible(true) -- Show logout button when authorized
    script_list:set_visible(true)
    load_button:set_visible(true)
    unload_button:set_visible(true)
    unload_all_button:set_visible(true)
end

local function show_auth_hide_list()
    username_text:set_visible(true) -- Changed from user_key_text
    paste_button:set_visible(true)
    authorize_button:set_visible(true)
    logout_button:set_visible(false) -- Hide logout button when logged out
    script_list:set_visible(false)
    load_button:set_visible(false)
    unload_button:set_visible(false)
    unload_all_button:set_visible(false)
end

local db_key = "centrum_username" -- Changed from centrum_user_key
local saved_username = database.read(db_key) or "" -- Changed from saved_key
username_text:set(saved_username) -- Changed from user_key_text

-- Logout function
local function logout()
    -- Clear saved username
    database.write(db_key, "")
    username_text:set("") -- Changed from user_key_text
    
    -- Unload all scripts
    for _, script in ipairs(scripts) do
        if script.loaded then
            script.loaded = false
        end
    end
    database.write("centrum_loader", {})
    client.reload_active_scripts()
    
    -- Reset UI to login state
    show_auth_hide_list()
    
    -- Notify user
    notify.new_bottom({ { 'Logged out successfully', true } })
    send_log("Logout", "User logged out successfully", saved_username, current_hwid) -- Changed from saved_key
end

logout_button:set_callback(logout)

local function authorize()
    local username = username_text:get()
    if username == "" then
        notify.new_bottom({ { 'Please enter a username' } })
        send_log("Authorization Attempt", "Empty username provided", username, current_hwid)
        return
    end

    local custom_http = http_req
    custom_http.get("https://raw.githubusercontent.com/celexuw-glitch/centrumental/refs/heads/main/data/accounts/profiles.json", function(success, response)
        if not success or response.status ~= 200 then
            notify.new_bottom({ { 'Failed to fetch user data' } })
            send_log("Authorization Error", "Failed to fetch user data: HTTP " .. tostring(response.status) .. " - " .. tostring(response.body or "No response body"), username, current_hwid)
            return
        end

        -- Log response for debugging
        client.log("Response body: " .. tostring(response.body))

        local success, user_data = pcall(json.parse, response.body)
        if not success then
            notify.new_bottom({ { 'Invalid JSON data received' } })
            send_log("Authorization Error", "Failed to parse JSON: " .. tostring(user_data) .. " - Body: " .. tostring(response.body or "No response body"), username, current_hwid)
            return
        end

        local user_info = nil
        local user_key = nil
        for key, info in pairs(user_data) do
            if info.username == username then
                user_info = info
                user_key = info.key -- Store the key field for HWID binding
                break
            end
        end

        if not user_info then
            notify.new_bottom({ { 'Invalid username' } })
            send_log("Authorization Error", "Invalid username", username, current_hwid)
            return
        end

        local hwid = user_info.hwid or "Unknown"
        local user_luas = user_info.luas or {} -- Changed from types to luas

        custom_http.get("https://raw.githubusercontent.com/celexuw-glitch/centrumental/refs/heads/main/data/accounts/banned.json", function(ban_success, ban_response)
            if not ban_success or ban_response.status ~= 200 then
                notify.new_bottom({ { 'Failed to fetch ban data' } })
                send_log("Authorization Error", "Failed to fetch ban data: HTTP " .. tostring(ban_response.status), username, current_hwid)
                return
            end

            local banned_data = json.parse(ban_response.body)
            local is_banned = false
            local ban_reason = "No reason provided"
            local banned_by = "Unknown"
            for _, ban in ipairs(banned_data) do
                if ban.hwid == current_hwid or ban.user_key == username then
                    is_banned = true
                    ban_reason = ban.reason or "No reason provided"
                    banned_by = ban.banned_by or "Unknown"
                    break
                end
            end

            if is_banned then
                notify.new_bottom({ { 'You are banned: ' .. ban_reason .. ' by ' .. banned_by } })
                client.color_log(menu_r, menu_g, menu_b, "Centrum ~\0")
                client.color_log(255, 0, 0, " You are banned: " .. ban_reason .. " by " .. banned_by)
                send_log("Authorization Failed", "User banned: " .. ban_reason .. " by " .. banned_by, username, current_hwid)
                show_auth_hide_list()
                return
            end

            custom_http.get("https://raw.githubusercontent.com/celexuw-glitch/centrumental/refs/heads/main/data/accounts/hwid.json", function(hwid_success, hwid_response)
                if not hwid_success or hwid_response.status ~= 200 then
                    notify.new_bottom({ { 'Failed to fetch HWID data' } })
                    send_log("Authorization Error", "Failed to fetch HWID data: HTTP " .. tostring(hwid_response.status), username, current_hwid)
                    return
                end

                local hwid_data = json.parse(hwid_response.body)
                local bound_hwid = hwid_data[key] -- Use the key field from profiles.json

                if bound_hwid then
                    if bound_hwid ~= current_hwid then
                        notify.new_bottom({ { 'HWID mismatch' } })
                        client.color_log(menu_r, menu_g, menu_b, "Centrum ~\0")
                        client.color_log(255, 0, 0, " HWID mismatch")
                        send_log("Authorization Failed", "HWID mismatch", username, current_hwid)
                        return
                    end
                else
                    if user_key then
                        hwid_data[user_key] = current_hwid
                        local new_json = json.stringify(hwid_data)

                        local token = "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"
                        local api_url = "https://github.com/celexuw-glitch/centrumental/blob/main/data/accounts/hwid.json"
                        local headers = {
                            Authorization = "token " .. token,
                            Accept = "application/vnd.github.v3+json"
                        }

custom_http.get(api_url, {headers = headers}, function(api_success, api_response)
    if not api_success or api_response.status ~= 200 then
        notify.new_bottom({ { 'Failed to get HWID file info' } })
        send_log("HWID Binding Error", "Failed to get HWID file info: HTTP " .. tostring(api_response.status), username, current_hwid)
        return
    end

    local success, api_data = pcall(json.parse, api_response.body)
    if not success then
        notify.new_bottom({ { 'Invalid JSON in HWID file response: ' .. tostring(api_data) } })
        send_log("HWID Binding Error", "Invalid JSON in HWID file response: " .. tostring(api_data) .. " - Body: " .. tostring(api_response.body), username, current_hwid)
        return
    end

                            local api_data = json.parse(api_response.body)
                            local sha = api_data.sha

                            local put_data = {
                                message = "Bind HWID for username " .. username,
                                content = base64.encode(new_json),
                                sha = sha
                            }
                            local put_body = json.stringify(put_data)
                            local put_headers = {
                                Authorization = "token " .. token,
                                Accept = "application/vnd.github.v3+json",
                                ["Content-Type"] = "application/json"
                            }

                            custom_http.put(api_url, {headers = put_headers, body = put_body}, function(put_success, put_response)
                                if put_success and put_response.status == 200 then
                                    notify.new_bottom({ { 'HWID bound successfully' } })
                                    client.color_log(menu_r, menu_g, menu_b, "Centrum ~\0")
                                    client.color_log(0, 255, 0, " HWID bound successfully")
                                    send_log("HWID Binding", "HWID bound successfully for username " .. username, username, current_hwid)
                                else
                                    notify.new_bottom({ { 'Failed to bind HWID' } })
                                    client.color_log(menu_r, menu_g, menu_b, "Centrum ~\0")
                                    client.color_log(255, 0, 0, " Failed to bind HWID")
                                    send_log("HWID Binding Error", "Failed to bind HWID: HTTP " .. tostring(put_response.status), username, current_hwid)
                                    return
                                end
                            end)
                        end)
                    end
                end

                -- Filter scripts based on user_types from users.json
                local function normalize_script_name(name)
                    -- Remove special characters and normalize for comparison
                    return name:gsub("\vÃ®Ë†Âº\r", ""):gsub("\v{ Real }\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
                end

                local all_scripts = {
                    {name = " Resolver Stable", url = "https://raw.githubusercontent.com/oword/gamesense-workshop-luas/refs/heads/main/Better%20scope%20overlay.lua", loaded = false},
                    {name = " Resolver Debug", url = "https://raw.githubusercontent.com/oword/gamesense-workshop-luas/refs/heads/main/Better%20scope%20overlay.lua", loaded = false},
                    {name = " Resolver Legend", url = "https://raw.githubusercontent.com/celexuw-glitch/centrumental/refs/heads/main/21321321231212321321321321", loaded = false}
                }
                scripts = {}
                script_names = {}
                for _, script in ipairs(all_scripts) do
                    for _, user_type in ipairs(user_luas) do
                        if normalize_script_name(script.name) == user_type then
                            table.insert(scripts, script)
                            table.insert(script_names, script.name) -- Keep original name for display
                            break
                        end
                    end
                end

                if #scripts == 0 then
                    notify.new_bottom({ { 'No authorized scripts available' } })
                    send_log("Authorization Warning", "No authorized scripts available for user", username, current_hwid)
                    return
                end

                script_list:update(script_names)
                notify.new_bottom({ { 'Authorized! Loaded ' .. #script_names .. ' scripts.' } })
                client.color_log(menu_r, menu_g, menu_b, "Centrum ~\0")
                client.color_log(210, 210, 210, " Authorized! Loaded " .. #script_names .. " scripts.")
                hide_auth_show_list()
                send_log("Successful Authorization", "Authorized successfully, loaded " .. #script_names .. " scripts", username, current_hwid, script_names)
            end)
        end)
    end)
end

authorize_button:set_callback(authorize)
if saved_username ~= "" then -- Changed from saved_key
    authorize()
end

local function load_script_by_name(name)
    for _, script in ipairs(scripts) do
        if script.name == name then
            http.get(script.url, function(success, response)
                if not success or response.status ~= 200 then
                    notify.new_bottom({ { 'Failed to download ' .. script.name } })
                    return
                end

                local chunk, err = load(response.body, script.name)
                if not chunk then
                    notify.new_bottom({ { 'Compile error: ' .. (err or 'unknown') } })
                    return
                end

                local env = setmetatable({}, { __index = _G })
                setfenv(chunk, env)
                local ok, res = pcall(chunk)
                if not ok then
                    notify.new_bottom({ { 'Runtime error: ' .. (res or 'unknown') } })
                    return
                end

                script.loaded = true
                notify.new_bottom({ { 'Loaded ' .. script.name, true } })
            end)
            break
        end
    end
end

for name, _ in pairs(loaded_scripts) do
    load_script_by_name(name)
end

load_button:set_callback(function()
    local sel_idx = script_list:get()
    if not sel_idx then
        notify.new_bottom({ { 'No script selected' } })
        return
    end

    local script = scripts[sel_idx + 1]
    if not script then return end

    if script.loaded then
        notify.new_bottom({ { script.name .. ' is already loaded' } })
        return
    end

    http.get(script.url, function(success, response)
        if not success or response.status ~= 200 then
            notify.new_bottom({ { 'Failed to download ' .. script.name } })
            return
        end

        local chunk, err = load(response.body, script.name)
        if not chunk then
            notify.new_bottom({ { 'Compile error: ' .. (err or 'unknown') } })
            return
        end

        local env = setmetatable({}, { __index = _G })
        setfenv(chunk, env)
        local ok, res = pcall(chunk)
        if not ok then
            notify.new_bottom({ { 'Runtime error: ' .. (res or 'unknown') } })
            return
        end

        loaded_scripts[script.name] = true
        database.write("centrum_loader", loaded_scripts)
        script.loaded = true
        notify.new_bottom({ { 'Successfully loaded ' .. script.name, true } })
    end)
end)

unload_button:set_callback(function()
    local sel_idx = script_list:get()
    if not sel_idx then
        notify.new_bottom({ { 'No script selected' } })
        return
    end

    local script = scripts[sel_idx + 1]
    if not script then return end

    if not script.loaded then
        notify.new_bottom({ { script.name .. ' is not loaded' } })
        return
    end

    loaded_scripts[script.name] = nil
    database.write("centrum_loader", loaded_scripts)
    script.loaded = false
    client.reload_active_scripts()
    notify.new_bottom({ { 'Unloaded ' .. script.name, true } })
end)

unload_all_button:set_callback(function()
    local unloaded_count = 0
    for _, script in ipairs(scripts) do
        if script.loaded then
            script.loaded = false
            unloaded_count = unloaded_count + 1
        end
    end
    database.write("centrum_loader", {})
    client.reload_active_scripts()
    notify.new_bottom({ { 'Unloaded ' .. unloaded_count .. ' scripts', true } })
end)