if module then return end
local strfind, type, setmetatable, setfenv, _G = strfind, type, setmetatable, setfenv, getfenv(0)

local PRIVATE, PUBLIC, FIELD, ACCESSOR, MUTATOR = 0, 1, 2, 4, 6
local MODES = { FIELD, ACCESSOR, MUTATOR }
local READ, WRITE = '', '='
local OPERATION = { [FIELD]=READ, [ACCESSOR]=READ, [MUTATOR]=WRITE }
local META = { get=ACCESSOR, set=MUTATOR }

local function error(msg, ...) return _G.error(format(msg or '', unpack(arg)) .. '\n' .. debugstack(), 0) end

local nop, id = function() end, function(v) return v end

local function proxy_mt(fields, mutators)
	return { __metatable=false, __index=fields, __newindex=function(_, k, v) return mutators[k](v) end }
end

local nop_default_mt, definition_helper_mt, require, include, create_module
local loaded, _interface, _environment, _access, _name = {}, {}, {}, {}, {}

nop_default_mt = { __index=function() return nop end }

definition_helper_mt = { __metatable=false }
function definition_helper_mt:__index(k)
	_name[self] = _name[self] and error('Invalid modifier "%s".', k) or k
	return self
end
function definition_helper_mt:__newindex(k, v)
	local module, name, mode
	module, name = loaded[self], _name[self]
	if name then mode = META[k] or error('Invalid modifier "%s"', k) else name, mode = k, FIELD end
	if type(name) ~= 'string' or not strfind(name, '^[_%a][_%w]*') then error('Invalid identifier "%s".', name) end
	module.defined[name .. OPERATION[mode]] = module.defined[name .. OPERATION[mode]] and error('Duplicate identifier "%s".', name) or true
	module[mode][name], module[_access[self] + mode][name] = v, v
	_access[self], _name[self] = nil, nil
end

function require(name) if not loaded[name] then create_module(name) end return _interface[name] end

function include(self, name)
	local module = name and loaded[name] or error('No module "%s".', name)
	for _, mode in MODES do
		for k, v in module[PUBLIC + mode] do
			if not self.defined[k .. OPERATION[mode]] or error('Import conflict for "%s".', k) then
				self.defined[k .. OPERATION[mode]], self[mode][k] = true, v
			end
		end
	end
end

function create_module(name)
	if type(name) ~= 'string' then error('Invalid module name "%s".', name) end
	local P, environment, interface, definition_helper, modifiers, accessors, mutators, fields, public_accessors, public_mutators, public_fields
	environment, interface, definition_helper = {}, {}, setmetatable({}, definition_helper_mt)
	accessors = { private=function() _access[definition_helper] = PRIVATE; return definition_helper end, public=function() _access[definition_helper] = PUBLIC; return definition_helper end }
	mutators = setmetatable({ _=nop }, { __index=function(_, k) return function(v) _G[k] = v end end })
	fields = setmetatable(
		{ _M=environment, _G=_G, require=require, include=function(interface) include(P, interface) end, error=error, nop=nop, id=id },
		{ __index=function(_, k) local accessor = accessors[k]; if accessor then return accessor() else return _G[k] end end }
	)
	public_accessors = setmetatable({}, nop_default_mt)
	public_mutators = setmetatable({}, nop_default_mt)
	public_fields = setmetatable({}, { __index=function(_, k) return public_accessors[k]() end })
	setmetatable(environment, proxy_mt(fields, mutators))
	setmetatable(interface, proxy_mt(public_fields, public_mutators))
	P = {
		defined = { _M=true, _G=true, require=true, include=true, error=true, nop=true, id=true, public=true, private=true, ['_=']=true },
		[ACCESSOR] = accessors,
		[MUTATOR] = mutators,
		[FIELD] = fields,
		[PUBLIC + ACCESSOR] = public_accessors,
		[PUBLIC + MUTATOR] = public_mutators,
		[PUBLIC + FIELD] = public_fields,
	}
	_environment[name], _interface[name] = environment, interface
	loaded[name], loaded[definition_helper] = P, P
end

function module(name) if not loaded[name] then create_module(name) end setfenv(2, _environment[name]) end
function library(name) if loaded[name] then _G.error(nil) end create_module(name) setfenv(2, _environment[name]) end