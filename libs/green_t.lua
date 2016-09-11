green_t = module
local next, getn, setn, tremove, type, setmetatable = next, getn, table.setn, tremove, type, setmetatable

-- TODO recursive releasing with specified depth, maybe allow setting "release structure" on creation for easier releasing, mandatory operation table mandate + comply/fulfill functions to ensure something is being released?

local wipe, acquire, release, set_auto_release
do
	local pool, pool_size, overflow_pool, auto_release = {}, 0, setmetatable({}, { __mode='k' }), {}

	function wipe(t)
		setmetatable(t, nil)
		for k in t do t[k] = nil end
		t.reset, t.reset = nil, 1
		setn(t, 0)
	end
	public.wipe = wipe

	CreateFrame('Frame'):SetScript('OnUpdate', function()
		for t in auto_release do release(t) end
		wipe(auto_release)
	end)

	function acquire()
		if pool_size > 0 then
			pool_size = pool_size - 1
			return pool[pool_size + 1]
		end
		local t = next(overflow_pool)
		if t then
			overflow_pool[t] = nil
			return t
		end
		return {}
	end
	public.acquire = acquire

	function release(t)
		wipe(t)
		auto_release[t] = nil
		if pool_size < 50 then
			pool_size = pool_size + 1
			pool[pool_size] = t
		else
			overflow_pool[t] = true
		end
	end
	public.release = release

	function set_auto_release(v, enable)
		if type(v) ~= 'table' then return end
		auto_release[v] = enable and true or nil
	end
	public.set_auto_release = set_auto_release
end

public.t.get = acquire
function public.tt.get()
	local t = acquire()
	set_auto_release(t, true)
	return t
end

public.auto = setmetatable({}, {
	__metatable = false,
	__newindex = function(_, k, v) set_auto_release(k, v) end,
})
public.temp = setmetatable({}, {
	__metatable = false,
	__sub = function(_, v) set_auto_release(v, false); return v end,
})
public.perm = setmetatable({}, {
	__metatable = false,
	__sub = function(_, v) set_auto_release(v, true); return v end,
})

public.init = setmetatable({}, {
	__metatable = false,
	__newindex = function(_, t, init)
		wipe(t)
		for k, v in init do
			t[k] = v
			setn(t, getn(init))
		end
	end
})

do
	local function ret(t)
		if getn(t) > 0 then
			return tremove(t, 1), ret(t)
		else
			release(t)
		end
	end
	public.ret = ret
end

public.empty = setmetatable({}, { __metatable=false, __newindex=nop })

local vararg
do
	local MAXPARAMS = 100

	local code = [[
		local f, setn, acquire, set_auto_release = f, setn, acquire, set_auto_release
		return function(
	]]
	for i = 1, MAXPARAMS - 1 do
		code = code .. format('a%d,', i)
	end
	code = code .. [[
		overflow)
		if overflow ~= nil then error("Vararg overflow.") end
		local n = 0
		repeat
	]]
	for i = MAXPARAMS - 1, 1, -1 do
		code = code .. format('if a%1$d ~= nil then n = %1$d; break end;', i)
	end
	code = code .. [[
		until true
		local t = acquire()
		set_auto_release(t, true)
		setn(t, n)
		repeat
	]]
	for i = 1, MAXPARAMS - 1 do
		code = code .. format('if %1$d > n then break end; t[%1$d] = a%1$d;', i)
	end
	code = code .. [[
		until true
		return f(t)
		end
	]]

	function vararg(f)
		local chunk = loadstring(code)
		setfenv(chunk, {f=f, setn=setn, acquire=acquire, set_auto_release=set_auto_release})
		return chunk()
	end
	public.vararg = vararg
end

public.A = vararg(function(arg)
	set_auto_release(arg, false)
	return arg
end)
public.S = vararg(function(arg)
	local t = acquire()
	for _, v in arg do
		t[v] = true
	end
	return t
end)
public.T = vararg(function(arg)
	local t = acquire()
	for i = 1, getn(arg), 2 do
		t[arg[i]] = arg[i + 1]
	end
	return t
end)