local Util = (function()
	local function a(b)
		for c, d in pairs(b) do
			b[d] = true
		end
		return b
	end
	local function e(b)
		local f = 0
		for c in pairs(b) do
			f = f + 1
		end
		return f
	end
	local function g(b, h)
		if b.Print then
			return b.Print()
		end
		h = h or 0
		local i = e(b) > 1
		local j = ("\t"):rep(h + 1)
		local k = "{" .. (i and "\n" or "")
		for l, d in pairs(b) do
			if type(d) ~= "function" then
				k = k .. (i and j or "")
				if type(l) == "number" then
				elseif type(l) == "string" and l:match("^[%a_][%w_]*$") then
					k = k .. l .. " = "
				elseif type(l) == "string" then
					k = k .. "[\"" .. l .. "\"] = "
				else
					k = k .. "[" .. tostring(l) .. "] = "
				end
				if type(d) == "string" then
					k = k .. "\"" .. d .. "\""
				elseif type(d) == "number" then
					k = k .. d
				elseif type(d) == "table" then
					k = k .. g(d, h + (i and 1 or 0))
				else
					k = k .. tostring(d)
				end
				if next(b, l) then
					k = k .. ","
				end
				if i then
					k = k .. "\n"
				end
			end
		end
		k = k .. (i and ("\t"):rep(h) or "") .. "}"
		return k
	end
	local function m(n)
		if n:match("\n") then
			local o = {}
			for p in n:gmatch("[^\n]*") do
				table.insert(o, p)
			end
			assert(#o > 0)
			return o
		else
			return {n}
		end
	end
	local function q(r, ...)
		return print(r:format(...))
	end
	local function s(n)
		return n:match("^%s*(.-)%s*$"):gsub(",%.%.%.", ", ..."):gsub(", \n", ",\n")
	end
	return {
		stripstr = s,
		PrintTable = g,
		CountTable = e,
		lookupify = a,
		splitLines = m,
		printf = q
	}
end)()
local Scope = (function()
	local a = {
		new = function(self, b)
			local c = {
				Parent = b,
				Locals = {},
				Globals = {},
				oldLocalNamesMap = {},
				oldGlobalNamesMap = {},
				Children = {}
			}
			if b then
				table.insert(b.Children, c)
			end
			return setmetatable(c, {
				__index = self
			})
		end,
		AddLocal = function(self, d)
			table.insert(self.Locals, d)
		end,
		AddGlobal = function(self, d)
			table.insert(self.Globals, d)
		end,
		CreateLocal = function(self, e)
			local d
			d = self:GetLocal(e)
			if d then
				return d
			end
			d = {}
			d.Scope = self
			d.Name = e
			d.IsGlobal = false
			d.CanRename = true
			d.References = 1
			self:AddLocal(d)
			return d
		end,
		GetLocal = function(self, e)
			for f, g in pairs(self.Locals) do
				if g.Name == e then
					return g
				end
			end
			if self.Parent then
				return self.Parent:GetLocal(e)
			end
		end,
		GetOldLocal = function(self, e)
			if self.oldLocalNamesMap[e] then
				return self.oldLocalNamesMap[e]
			end
			return self:GetLocal(e)
		end,
		mapLocal = function(self, e, g)
			self.oldLocalNamesMap[e] = g
		end,
		GetOldGlobal = function(self, e)
			if self.oldGlobalNamesMap[e] then
				return self.oldGlobalNamesMap[e]
			end
			return self:GetGlobal(e)
		end,
		mapGlobal = function(self, e, g)
			self.oldGlobalNamesMap[e] = g
		end,
		GetOldVariable = function(self, e)
			return self:GetOldLocal(e) or self:GetOldGlobal(e)
		end,
		RenameLocal = function(self, h, i)
			h = type(h) == "string" and h or h.Name
			local j = false
			local g = self:GetLocal(h)
			if g then
				g.Name = i
				self:mapLocal(h, g)
				j = true
			end
			if not j and self.Parent then
				self.Parent:RenameLocal(h, i)
			end
		end,
		RenameGlobal = function(self, h, i)
			h = type(h) == "string" and h or h.Name
			local j = false
			local g = self:GetGlobal(h)
			if g then
				g.Name = i
				self:mapGlobal(h, g)
				j = true
			end
			if not j and self.Parent then
				self.Parent:RenameGlobal(h, i)
			end
		end,
		RenameVariable = function(self, h, i)
			h = type(h) == "string" and h or h.Name
			if self:GetLocal(h) then
				self:RenameLocal(h, i)
			else
				self:RenameGlobal(h, i)
			end
		end,
		GetAllVariables = function(self)
			local k = self:getVars(true)
			for f, d in pairs(self:getVars(false)) do
				table.insert(k, d)
			end
			return k
		end,
		getVars = function(self, l)
			local k = {}
			if l then
				for f, d in pairs(self.Children) do
					for m, n in pairs(d:getVars(true)) do
						table.insert(k, n)
					end
				end
			else
				for f, d in pairs(self.Locals) do
					table.insert(k, d)
				end
				for f, d in pairs(self.Globals) do
					table.insert(k, d)
				end
				if self.Parent then
					for f, d in pairs(self.Parent:getVars(false)) do
						table.insert(k, d)
					end
				end
			end
			return k
		end,
		CreateGlobal = function(self, e)
			local d
			d = self:GetGlobal(e)
			if d then
				return d
			end
			d = {}
			d.Scope = self
			d.Name = e
			d.IsGlobal = true
			d.CanRename = true
			d.References = 1
			self:AddGlobal(d)
			return d
		end,
		GetGlobal = function(self, e)
			for f, d in pairs(self.Globals) do
				if d.Name == e then
					return d
				end
			end
			if self.Parent then
				return self.Parent:GetGlobal(e)
			end
		end,
		GetVariable = function(self, e)
			return self:GetLocal(e) or self:GetGlobal(e)
		end,
		ObfuscateLocals = function(self, o, p)
			o = o or 7
			local q = p or "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuioplkjhgfdsazxcvbnm_"
			local r = p or "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuioplkjhgfdsazxcvbnm_1234567890"
			for s, g in pairs(self.Locals) do
				local t = ""
				local u = 0
				repeat
					local v = math.random(1, #q)
					t = t .. q:sub(v, v)
					for w = 1, math.random(0, u > 5 and 30 or o) do
						local v = math.random(1, #r)
						t = t .. r:sub(v, v)
					end
					u = u + 1
				until not self:GetVariable(t)
				self:RenameLocal(g.Name, t)
			end
		end,
		BeautifyVariables_ = function(x, y, z)
			local A = {}
			for s, g in pairs(x) do
				if not g.AssignedTo or not z then
					A[g.Name] = true
				end
			end
			local B = 1
			local C = 1
			local function D(g, e)
				g.Name = e
				for s, E in pairs(g.RenameList) do
					E(e)
				end
			end
			local function F(G)
				for s, g in pairs(G.VariableList) do
					local e = "L" .. B
					if g.Info.Type == "Argument" then
						e = e .. "arg" .. g.Info.Index
					elseif g.Info.Type == "LocalFunction" then
						e = e .. "func"
					elseif g.Info.Type == "ForRange" then
						e = e .. "forvar" .. g.Info.Index
					end
					D(g, e)
					B = B + 1
				end
				for s, G in pairs(G.ChildScopeList) do
					F(G)
				end
			end
			F(y)
		end,
		BeautifyVariables = function(self)
			local B = 1
			for s, g in pairs(self.Locals) do
				local e = "L" .. B
				self:RenameLocal(g, e)
				B = B + 1
			end
		end
	}
	return a
end)()
local ParseLua = (function()
	local a = Util.lookupify
	local b = a({" ", "\n", "\t", "\r"})
	local c = {
		["\r"] = "\\r",
		["\n"] = "\\n",
		["\t"] = "\\t",
		["\""] = "\\\"",
		["'"] = "\\'"
	}
	local d = a({"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"})
	local e = a({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"})
	local f = a({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"})
	local g = a({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "F", "f"})
	local h = a({"+", "-", "*", "/", "^", "%", ",", "{", "}", "[", "]", "(", ")", ";", "#"})
	local j = a({"and", "break", "continue", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"})
	local function k(l)
		local m = {}
		local n, o = pcall(function()
			local p = 1
			local q = 1
			local r = 1
			local function s()
				local t = l:sub(p, p)
				if t == "\n" then
					r = 1
					q = q + 1
				else
					r = r + 1
				end
				p = p + 1
				return t
			end
			local function u(v)
				v = v or 0
				return l:sub(p + v, p + v)
			end
			local function w(x)
				local t = u()
				for y = 1, #x do
					if t == x:sub(y, y) then
						return s()
					end
				end
			end
			local function z(o)
				return error(">> :" .. q .. ":" .. r .. ": " .. o, 0)
			end
			local function A()
				local B = p
				if u() == "[" then
					local C = 0
					local D = 1
					while u(C + 1) == "=" do
						C = C + 1
					end
					if u(C + 1) == "[" then
						for E = 0, C + 1 do
							s()
						end
						local F = p
						while true do
							if u() == "" then
								z("Expected `]" .. ("="):rep(C) .. "]` near <eof>.", 3)
							end
							local G = true
							if u() == "]" then
								for y = 1, C do
									if u(y) ~= "=" then
										G = false
									end
								end
								if u(C + 1) ~= "]" then
									G = false
								end
							else
								if u() == "[" then
									local H = true
									for y = 1, C do
										if u(y) ~= "=" then
											H = false
											break
										end
									end
									if u(C + 1) == "[" and H then
										D = D + 1
										for y = 1, C + 2 do
											s()
										end
									end
								end
								G = false
							end
							if G then
								D = D - 1
								if D == 0 then
									break
								else
									for y = 1, C + 2 do
										s()
									end
								end
							else
								s()
							end
						end
						local I = l:sub(F, p - 1)
						for y = 0, C + 1 do
							s()
						end
						local J = l:sub(B, p - 1)
						return I, J
					else
						return nil
					end
				else
					return nil
				end
			end
			while true do
				local K = {}
				local L = ""
				local M = false
				while true do
					local t = u()
					if t == "#" and u(1) == "!" and q == 1 then
						s()
						s()
						L = "#!"
						while u() ~= "\n" and u() ~= "" do
							L = L .. s()
						end
						local N = {
							Type = "Comment",
							CommentType = "Shebang",
							Data = L,
							Line = q,
							Char = r
						}
						N.Print = function()
							return "<" .. (N.Type .. (" "):rep(7 - #N.Type)) .. "  " .. (N.Data or "") .. " >"
						end
						L = ""
						table.insert(K, N)
					end
					if t == " " or t == "\t" then
						local O = s()
						table.insert(K, {
							Type = "Whitespace",
							Line = q,
							Char = r,
							Data = O
						})
					elseif t == "\n" or t == "\r" then
						local P = s()
						if L ~= "" then
							local N = {
								Type = "Comment",
								CommentType = M and "LongComment" or "Comment",
								Data = L,
								Line = q,
								Char = r
							}
							N.Print = function()
								return "<" .. (N.Type .. (" "):rep(7 - #N.Type)) .. "  " .. (N.Data or "") .. " >"
							end
							table.insert(K, N)
							L = ""
						end
						table.insert(K, {
							Type = "Whitespace",
							Line = q,
							Char = r,
							Data = P
						})
					elseif t == "-" and u(1) == "-" then
						s()
						s()
						L = L .. "--"
						local E, Q = A()
						if Q then
							L = L .. Q
							M = true
						else
							while u() ~= "\n" and u() ~= "" do
								L = L .. s()
							end
						end
					else
						break
					end
				end
				if L ~= "" then
					local N = {
						Type = "Comment",
						CommentType = M and "LongComment" or "Comment",
						Data = L,
						Line = q,
						Char = r
					}
					N.Print = function()
						return "<" .. (N.Type .. (" "):rep(7 - #N.Type)) .. "  " .. (N.Data or "") .. " >"
					end
					table.insert(K, N)
				end
				local R = q
				local S = r
				local T = ":" .. q .. ":" .. r .. ":> "
				local t = u()
				local U = nil
				if t == "" then
					U = {
						Type = "Eof"
					}
				elseif e[t] or d[t] or t == "_" then
					local B = p
					repeat
						s()
						t = u()
					until not (e[t] or d[t] or f[t] or t == "_")
					local V = l:sub(B, p - 1)
					if j[V] then
						U = {
							Type = "Keyword",
							Data = V
						}
					else
						U = {
							Type = "Ident",
							Data = V
						}
					end
				elseif f[t] or u() == "." and f[u(1)] then
					local B = p
					if t == "0" and u(1):lower() == "x" then
						s()
						s()
						while g[u()] do
							s()
						end
						if w("Pp") then
							w("+-")
							while f[u()] do
								s()
							end
						end
					else
						while f[u()] do
							s()
						end
						if w(".") then
							while f[u()] do
								s()
							end
						end
						if w("Ee") then
							w("+-")
							while f[u()] do
								s()
							end
						end
					end
					U = {
						Type = "Number",
						Data = l:sub(B, p - 1)
					}
				elseif t == "'" or t == "\"" then
					local B = p
					local W = s()
					local F = p
					while true do
						local t = s()
						if t == "\\" then
							s()
						elseif t == W then
							break
						elseif t == "" then
							z("Unfinished string near <eof>")
						end
					end
					local X = l:sub(F, p - 2)
					local Y = l:sub(B, p - 1)
					U = {
						Type = "string",
						Data = Y,
						Constant = X
					}
				elseif t == "[" then
					local X, Z = A()
					if Z then
						U = {
							Type = "string",
							Data = Z,
							Constant = X
						}
					else
						s()
						U = {
							Type = "Symbol",
							Data = "["
						}
					end
				elseif w(">=<") then
					if w("=") then
						U = {
							Type = "Symbol",
							Data = t .. "="
						}
					else
						U = {
							Type = "Symbol",
							Data = t
						}
					end
				elseif w("~") then
					if w("=") then
						U = {
							Type = "Symbol",
							Data = "~="
						}
					else
						z("Unexpected symbol `~` in source.", 2)
					end
				elseif w(".") then
					if w(".") then
						if w(".") then
							U = {
								Type = "Symbol",
								Data = "..."
							}
						else
							U = {
								Type = "Symbol",
								Data = ".."
							}
						end
					else
						U = {
							Type = "Symbol",
							Data = "."
						}
					end
				elseif w(":") then
					if w(":") then
						U = {
							Type = "Symbol",
							Data = "::"
						}
					else
						U = {
							Type = "Symbol",
							Data = ":"
						}
					end
				elseif h[t] then
					s()
					U = {
						Type = "Symbol",
						Data = t
					}
				else
					local _, a0 = A()
					if _ then
						U = {
							Type = "string",
							Data = a0,
							Constant = _
						}
					else
						z("Unexpected Symbol `" .. t .. "` in source.", 2)
					end
				end
				U.LeadingWhite = K
				U.Line = R
				U.Char = S
				U.Print = function()
					return "<" .. (U.Type .. (" "):rep(7 - #U.Type)) .. "  " .. (U.Data or "") .. " >"
				end
				m[#m + 1] = U
				if U.Type == "Eof" then
					break
				end
			end
		end)
		if not n then
			return false, o
		end
		local a1 = {}
		local a2 = {}
		local p = 1
		function a1:getp()
			return p
		end
		function a1:setp(v)
			p = v
		end
		function a1:getTokenList()
			return m
		end
		function a1:Peek(v)
			v = v or 0
			return m[math.min(#m, p + v)]
		end
		function a1:Get(a3)
			local a4 = m[p]
			p = math.min(p + 1, #m)
			if a3 then
				table.insert(a3, a4)
			end
			return a4
		end
		function a1:Is(a4)
			return a1:Peek().Type == a4
		end
		function a1:Save()
			a2[#a2 + 1] = p
		end
		function a1:Commit()
			a2[#a2] = nil
		end
		function a1:Restore()
			p = a2[#a2]
			a2[#a2] = nil
		end
		function a1:ConsumeSymbol(a5, a3)
			local a4 = self:Peek()
			if a4.Type == "Symbol" then
				if a5 then
					if a4.Data == a5 then
						self:Get(a3)
						return true
					else
						return nil
					end
				else
					self:Get(a3)
					return a4
				end
			else
				return nil
			end
		end
		function a1:ConsumeKeyword(a6, a3)
			local a4 = self:Peek()
			if a4.Type == "Keyword" and a4.Data == a6 then
				self:Get(a3)
				return true
			else
				return nil
			end
		end
		function a1:IsKeyword(a6)
			local a4 = a1:Peek()
			return a4.Type == "Keyword" and a4.Data == a6
		end
		function a1:IsSymbol(a7)
			local a4 = a1:Peek()
			return a4.Type == "Symbol" and a4.Data == a7
		end
		function a1:IsEof()
			return a1:Peek().Type == "Eof"
		end
		return true, a1
	end
	local function a8(l)
		local n, a1
		if type(l) ~= "table" then
			n, a1 = k(l)
		else
			n, a1 = true, l
		end
		if not n then
			return false, a1
		end
		local function a9(aa)
			local o = ">> :" .. a1:Peek().Line .. ":" .. a1:Peek().Char .. ": " .. aa .. "\n"
			local ab = 0
			if type(l) == "string" then
				for q in l:gmatch("[^\n]*\n?") do
					if q:sub(-1, -1) == "\n" then
						q = q:sub(1, -2)
					end
					ab = ab + 1
					if ab == a1:Peek().Line then
						o = o .. ">> `" .. q:gsub("\t", "\t") .. "`\n"
						for y = 1, a1:Peek().Char do
							local t = q:sub(y, y)
							if t == "\t" then
								o = o .. "\t"
							else
								o = o .. " "
							end
						end
						o = o .. "   ^^^^"
						break
					end
				end
			end
			return o
		end
		local ac = 0
		local ad = {"_", "a", "b", "c", "d"}
		local function ae(af)
			local ag = Scope:new(af)
			ag.RenameVars = ag.ObfuscateLocals
			ag.ObfuscateVariables = ag.ObfuscateLocals
			ag.BeautifyVars = ag.BeautifyVariables
			ag.Print = function()
				return "<Scope>"
			end
			return ag
		end
		local ah
		local ai
		local aj, ak, al, am
		local function an(ag, a3)
			local ao = ae(ag)
			if not a1:ConsumeSymbol("(", a3) then
				return false, a9("`(` expected.")
			end
			local ap = {}
			local aq = false
			while not a1:ConsumeSymbol(")", a3) do
				if a1:Is("Ident") then
					local ar = ao:CreateLocal(a1:Get(a3).Data)
					ap[#ap + 1] = ar
					if not a1:ConsumeSymbol(",", a3) then
						if a1:ConsumeSymbol(")", a3) then
							break
						else
							return false, a9("`)` expected.")
						end
					end
				elseif a1:ConsumeSymbol("...", a3) then
					aq = true
					if not a1:ConsumeSymbol(")", a3) then
						return false, a9("`...` must be the last argument of a function.")
					end
					break
				else
					return false, a9("Argument name or `...` expected")
				end
			end
			local n, as = ai(ao)
			if not n then
				return false, as
			end
			if not a1:ConsumeKeyword("end", a3) then
				return false, a9("`end` expected after function body")
			end
			local at = {}
			at.AstType = "Function"
			at.Scope = ao
			at.Arguments = ap
			at.Body = as
			at.VarArg = aq
			at.Tokens = a3
			return true, at
		end
		function al(ag)
			local a3 = {}
			if a1:ConsumeSymbol("(", a3) then
				local n, au = ah(ag)
				if not n then
					return false, au
				end
				if not a1:ConsumeSymbol(")", a3) then
					return false, a9("`)` Expected.")
				end
				if false then
					au.ParenCount = (au.ParenCount or 0) + 1
					return true, au
				else
					local av = {}
					av.AstType = "Parentheses"
					av.Inner = au
					av.Tokens = a3
					return true, av
				end
			elseif a1:Is("Ident") then
				local aw = a1:Get(a3)
				local ax = ag:GetLocal(aw.Data)
				if not ax then
					ax = ag:GetGlobal(aw.Data)
					if not ax then
						ax = ag:CreateGlobal(aw.Data)
					else
						ax.References = ax.References + 1
					end
				else
					ax.References = ax.References + 1
				end
				local ay = {}
				ay.AstType = "VarExpr"
				ay.Name = aw.Data
				ay.Variable = ax
				ay.Tokens = a3
				return true, ay
			else
				return false, a9("primary expression expected")
			end
		end
		function am(ag, az)
			local n, aA = al(ag)
			if not n then
				return false, aA
			end
			while true do
				local a3 = {}
				if a1:IsSymbol(".") or a1:IsSymbol(":") then
					local a5 = a1:Get(a3).Data
					if not a1:Is("Ident") then
						return false, a9("<Ident> expected.")
					end
					local aw = a1:Get(a3)
					local aB = {}
					aB.AstType = "MemberExpr"
					aB.Base = aA
					aB.Indexer = a5
					aB.Ident = aw
					aB.Tokens = a3
					aA = aB
				elseif not az and a1:ConsumeSymbol("[", a3) then
					local n, au = ah(ag)
					if not n then
						return false, au
					end
					if not a1:ConsumeSymbol("]", a3) then
						return false, a9("`]` expected.")
					end
					local aB = {}
					aB.AstType = "IndexExpr"
					aB.Base = aA
					aB.Index = au
					aB.Tokens = a3
					aA = aB
				elseif not az and a1:ConsumeSymbol("(", a3) then
					local aC = {}
					while not a1:ConsumeSymbol(")", a3) do
						local n, au = ah(ag)
						if not n then
							return false, au
						end
						aC[#aC + 1] = au
						if not a1:ConsumeSymbol(",", a3) then
							if a1:ConsumeSymbol(")", a3) then
								break
							else
								return false, a9("`)` Expected.")
							end
						end
					end
					local aD = {}
					aD.AstType = "CallExpr"
					aD.Base = aA
					aD.Arguments = aC
					aD.Tokens = a3
					aA = aD
				elseif not az and a1:Is("string") then
					local aD = {}
					aD.AstType = "StringCallExpr"
					aD.Base = aA
					aD.Arguments = {a1:Get(a3)}
					aD.Tokens = a3
					aA = aD
				elseif not az and a1:IsSymbol("{") then
					local n, au = aj(ag)
					if not n then
						return false, au
					end
					local aD = {}
					aD.AstType = "TableCallExpr"
					aD.Base = aA
					aD.Arguments = {au}
					aD.Tokens = a3
					aA = aD
				else
					break
				end
			end
			return true, aA
		end
		function aj(ag)
			local a3 = {}
			if a1:Is("Number") then
				local aE = {}
				aE.AstType = "NumberExpr"
				aE.Value = a1:Get(a3)
				aE.Tokens = a3
				return true, aE
			elseif a1:Is("string") then
				local aF = {}
				aF.AstType = "StringExpr"
				aF.Value = a1:Get(a3)
				aF.Tokens = a3
				return true, aF
			elseif a1:ConsumeKeyword("nil", a3) then
				local aG = {}
				aG.AstType = "NilExpr"
				aG.Tokens = a3
				return true, aG
			elseif a1:IsKeyword("false") or a1:IsKeyword("true") then
				local aH = {}
				aH.AstType = "BooleanExpr"
				aH.Value = a1:Get(a3).Data == "true"
				aH.Tokens = a3
				return true, aH
			elseif a1:ConsumeSymbol("...", a3) then
				local aI = {}
				aI.AstType = "DotsExpr"
				aI.Tokens = a3
				return true, aI
			elseif a1:ConsumeSymbol("{", a3) then
				local aJ = {}
				aJ.AstType = "ConstructorExpr"
				aJ.EntryList = {}
				while true do
					if a1:IsSymbol("[", a3) then
						a1:Get(a3)
						local n, aK = ah(ag)
						if not n then
							return false, a9("Key Expression Expected")
						end
						if not a1:ConsumeSymbol("]", a3) then
							return false, a9("`]` Expected")
						end
						if not a1:ConsumeSymbol("=", a3) then
							return false, a9("`=` Expected")
						end
						local n, aL = ah(ag)
						if not n then
							return false, a9("Value Expression Expected")
						end
						aJ.EntryList[#aJ.EntryList + 1] = {
							Type = "Key",
							Key = aK,
							Value = aL
						}
					elseif a1:Is("Ident") then
						local aM = a1:Peek(1)
						if aM.Type == "Symbol" and aM.Data == "=" then
							local aK = a1:Get(a3)
							if not a1:ConsumeSymbol("=", a3) then
								return false, a9("`=` Expected")
							end
							local n, aL = ah(ag)
							if not n then
								return false, a9("Value Expression Expected")
							end
							aJ.EntryList[#aJ.EntryList + 1] = {
								Type = "KeyString",
								Key = aK.Data,
								Value = aL
							}
						else
							local n, aL = ah(ag)
							if not n then
								return false, a9("Value Exected")
							end
							aJ.EntryList[#aJ.EntryList + 1] = {
								Type = "Value",
								Value = aL
							}
						end
					elseif a1:ConsumeSymbol("}", a3) then
						break
					else
						local n, aL = ah(ag)
						aJ.EntryList[#aJ.EntryList + 1] = {
							Type = "Value",
							Value = aL
						}
						if not n then
							return false, a9("Value Expected")
						end
					end
					if a1:ConsumeSymbol(";", a3) or a1:ConsumeSymbol(",", a3) then
					elseif a1:ConsumeSymbol("}", a3) then
						break
					else
						return false, a9("`}` or table entry Expected")
					end
				end
				aJ.Tokens = a3
				return true, aJ
			elseif a1:ConsumeKeyword("function", a3) then
				local n, aN = an(ag, a3)
				if not n then
					return false, aN
				end
				aN.IsLocal = true
				return true, aN
			else
				return am(ag)
			end
		end
		local aO = a({"-", "not", "#"})
		local aP = 8
		local aQ = {
			["+"] = {6, 6},
			["-"] = {6, 6},
			["%"] = {7, 7},
			["/"] = {7, 7},
			["*"] = {7, 7},
			["^"] = {10, 9},
			[".."] = {5, 4},
			["=="] = {3, 3},
			["<"] = {3, 3},
			["<="] = {3, 3},
			["~="] = {3, 3},
			[">"] = {3, 3},
			[">="] = {3, 3},
			["and"] = {2, 2},
			["or"] = {1, 1}
		}
		function ak(ag, aR)
			local n, aS
			if aO[a1:Peek().Data] then
				local a3 = {}
				local aT = a1:Get(a3).Data
				n, aS = ak(ag, aP)
				if not n then
					return false, aS
				end
				local aU = {}
				aU.AstType = "UnopExpr"
				aU.Rhs = aS
				aU.Op = aT
				aU.OperatorPrecedence = aP
				aU.Tokens = a3
				aS = aU
			else
				n, aS = aj(ag)
				if not n then
					return false, aS
				end
			end
			while true do
				local aV = aQ[a1:Peek().Data]
				if aV and aV[1] > aR then
					local a3 = {}
					local aT = a1:Get(a3).Data
					local n, aW = ak(ag, aV[2])
					if not n then
						return false, aW
					end
					local aU = {}
					aU.AstType = "BinopExpr"
					aU.Lhs = aS
					aU.Op = aT
					aU.OperatorPrecedence = aV[1]
					aU.Rhs = aW
					aU.Tokens = a3
					aS = aU
				else
					break
				end
			end
			return true, aS
		end
		ah = function(ag)
			return ak(ag, 0)
		end
		local function aX(ag)
			local aY = nil
			local a3 = {}
			if a1:ConsumeKeyword("if", a3) then
				local aZ = {}
				aZ.AstType = "IfStatement"
				aZ.Clauses = {}
				repeat
					local n, a_ = ah(ag)
					if not n then
						return false, a_
					end
					if not a1:ConsumeKeyword("then", a3) then
						return false, a9("`then` expected.")
					end
					local n, b0 = ai(ag)
					if not n then
						return false, b0
					end
					aZ.Clauses[#aZ.Clauses + 1] = {
						Condition = a_,
						Body = b0
					}
				until not a1:ConsumeKeyword("elseif", a3)
				if a1:ConsumeKeyword("else", a3) then
					local n, b0 = ai(ag)
					if not n then
						return false, b0
					end
					aZ.Clauses[#aZ.Clauses + 1] = {
						Body = b0
					}
				end
				if not a1:ConsumeKeyword("end", a3) then
					return false, a9("`end` expected.")
				end
				aZ.Tokens = a3
				aY = aZ
			elseif a1:ConsumeKeyword("while", a3) then
				local b1 = {}
				b1.AstType = "WhileStatement"
				local n, a_ = ah(ag)
				if not n then
					return false, a_
				end
				if not a1:ConsumeKeyword("do", a3) then
					return false, a9("`do` expected.")
				end
				local n, b0 = ai(ag)
				if not n then
					return false, b0
				end
				if not a1:ConsumeKeyword("end", a3) then
					return false, a9("`end` expected.")
				end
				b1.Condition = a_
				b1.Body = b0
				b1.Tokens = a3
				aY = b1
			elseif a1:ConsumeKeyword("do", a3) then
				local n, b2 = ai(ag)
				if not n then
					return false, b2
				end
				if not a1:ConsumeKeyword("end", a3) then
					return false, a9("`end` expected.")
				end
				local b3 = {}
				b3.AstType = "DoStatement"
				b3.Body = b2
				b3.Tokens = a3
				aY = b3
			elseif a1:ConsumeKeyword("for", a3) then
				if not a1:Is("Ident") then
					return false, a9("<ident> expected.")
				end
				local b4 = a1:Get(a3)
				if a1:ConsumeSymbol("=", a3) then
					local b5 = ae(ag)
					local b6 = b5:CreateLocal(b4.Data)
					local n, b7 = ah(ag)
					if not n then
						return false, b7
					end
					if not a1:ConsumeSymbol(",", a3) then
						return false, a9("`,` Expected")
					end
					local n, b8 = ah(ag)
					if not n then
						return false, b8
					end
					local n, b9
					if a1:ConsumeSymbol(",", a3) then
						n, b9 = ah(ag)
						if not n then
							return false, b9
						end
					end
					if not a1:ConsumeKeyword("do", a3) then
						return false, a9("`do` expected")
					end
					local n, as = ai(b5)
					if not n then
						return false, as
					end
					if not a1:ConsumeKeyword("end", a3) then
						return false, a9("`end` expected")
					end
					local ba = {}
					ba.AstType = "NumericForStatement"
					ba.Scope = b5
					ba.Variable = b6
					ba.Start = b7
					ba.End = b8
					ba.Step = b9
					ba.Body = as
					ba.Tokens = a3
					aY = ba
				else
					local b5 = ae(ag)
					local bb = {b5:CreateLocal(b4.Data)}
					while a1:ConsumeSymbol(",", a3) do
						if not a1:Is("Ident") then
							return false, a9("for variable expected.")
						end
						bb[#bb + 1] = b5:CreateLocal(a1:Get(a3).Data)
					end
					if not a1:ConsumeKeyword("in", a3) then
						return false, a9("`in` expected.")
					end
					local bc = {}
					local n, bd = ah(ag)
					if not n then
						return false, bd
					end
					bc[#bc + 1] = bd
					while a1:ConsumeSymbol(",", a3) do
						local n, be = ah(ag)
						if not n then
							return false, be
						end
						bc[#bc + 1] = be
					end
					if not a1:ConsumeKeyword("do", a3) then
						return false, a9("`do` expected.")
					end
					local n, as = ai(b5)
					if not n then
						return false, as
					end
					if not a1:ConsumeKeyword("end", a3) then
						return false, a9("`end` expected.")
					end
					local ba = {}
					ba.AstType = "GenericForStatement"
					ba.Scope = b5
					ba.VariableList = bb
					ba.Generators = bc
					ba.Body = as
					ba.Tokens = a3
					aY = ba
				end
			elseif a1:ConsumeKeyword("repeat", a3) then
				local n, as = ai(ag)
				if not n then
					return false, as
				end
				if not a1:ConsumeKeyword("until", a3) then
					return false, a9("`until` expected.")
				end
				local n, bf = ah(as.Scope)
				if not n then
					return false, bf
				end
				local bg = {}
				bg.AstType = "RepeatStatement"
				bg.Condition = bf
				bg.Body = as
				bg.Tokens = a3
				aY = bg
			elseif a1:ConsumeKeyword("function", a3) then
				if not a1:Is("Ident") then
					return false, a9("Function name expected")
				end
				local n, bh = am(ag, true)
				if not n then
					return false, bh
				end
				local n, aN = an(ag, a3)
				if not n then
					return false, aN
				end
				aN.IsLocal = false
				aN.Name = bh
				aY = aN
			elseif a1:ConsumeKeyword("local", a3) then
				if a1:Is("Ident") then
					local bb = {a1:Get(a3).Data}
					while a1:ConsumeSymbol(",", a3) do
						if not a1:Is("Ident") then
							return false, a9("local var name expected")
						end
						bb[#bb + 1] = a1:Get(a3).Data
					end
					local bi = {}
					if a1:ConsumeSymbol("=", a3) then
						repeat
							local n, au = ah(ag)
							if not n then
								return false, au
							end
							bi[#bi + 1] = au
						until not a1:ConsumeSymbol(",", a3)
					end
					for y, aJ in pairs(bb) do
						bb[y] = ag:CreateLocal(aJ)
					end
					local bj = {}
					bj.AstType = "LocalStatement"
					bj.LocalList = bb
					bj.InitList = bi
					bj.Tokens = a3
					aY = bj
				elseif a1:ConsumeKeyword("function", a3) then
					if not a1:Is("Ident") then
						return false, a9("Function name expected")
					end
					local bh = a1:Get(a3).Data
					local bk = ag:CreateLocal(bh)
					local n, aN = an(ag, a3)
					if not n then
						return false, aN
					end
					aN.Name = bk
					aN.IsLocal = true
					aY = aN
				else
					return false, a9("local var or function def expected")
				end
			elseif a1:ConsumeSymbol("::", a3) then
				if not a1:Is("Ident") then
					return false, a9("Label name expected")
				end
				local bl = a1:Get(a3).Data
				if not a1:ConsumeSymbol("::", a3) then
					return false, a9("`::` expected")
				end
				local bm = {}
				bm.AstType = "LabelStatement"
				bm.Label = bl
				bm.Tokens = a3
				aY = bm
			elseif a1:ConsumeKeyword("return", a3) then
				local bn = {}
				if not a1:IsKeyword("end") then
					local n, bo = ah(ag)
					if n then
						bn[1] = bo
						while a1:ConsumeSymbol(",", a3) do
							local n, au = ah(ag)
							if not n then
								return false, au
							end
							bn[#bn + 1] = au
						end
					end
				end
				local bp = {}
				bp.AstType = "ReturnStatement"
				bp.Arguments = bn
				bp.Tokens = a3
				aY = bp
			elseif a1:ConsumeKeyword("break", a3) then
				local bq = {}
				bq.AstType = "BreakStatement"
				bq.Tokens = a3
				aY = bq
			elseif a1:ConsumeKeyword("continue", a3) then
				local bq = {}
				bq.AstType = "ContinueStatement"
				bq.Tokens = a3
				aY = bq
			else
				local n, br = am(ag)
				if not n then
					return false, br
				end
				if a1:IsSymbol(",") or a1:IsSymbol("=") then
					if (br.ParenCount or 0) > 0 then
						return false, a9("Can not assign to parenthesized expression, is not an lvalue")
					end
					local bs = {br}
					while a1:ConsumeSymbol(",", a3) do
						local n, bt = am(ag)
						if not n then
							return false, bt
						end
						bs[#bs + 1] = bt
					end
					if not a1:ConsumeSymbol("=", a3) then
						return false, a9("`=` Expected.")
					end
					local aW = {}
					local n, bu = ah(ag)
					if not n then
						return false, bu
					end
					aW[1] = bu
					while a1:ConsumeSymbol(",", a3) do
						local n, bv = ah(ag)
						if not n then
							return false, bv
						end
						aW[#aW + 1] = bv
					end
					local bw = {}
					bw.AstType = "AssignmentStatement"
					bw.Lhs = bs
					bw.Rhs = aW
					bw.Tokens = a3
					aY = bw
				elseif br.AstType == "CallExpr" or br.AstType == "TableCallExpr" or br.AstType == "StringCallExpr" then
					local aD = {}
					aD.AstType = "CallStatement"
					aD.Expression = br
					aD.Tokens = a3
					aY = aD
				else
					return false, a9("Assignment Statement Expected")
				end
			end
			if a1:IsSymbol(";") then
				aY.Semicolon = a1:Get(aY.Tokens)
			end
			return true, aY
		end
		local bx = a({"end", "else", "elseif", "until"})
		ai = function(ag)
			local by = {}
			by.Scope = ae(ag)
			by.AstType = "Statlist"
			by.Body = {}
			by.Tokens = {}
			while not bx[a1:Peek().Data] and not a1:IsEof() do
				local n, bz = aX(by.Scope)
				if not n then
					return false, bz
				end
				by.Body[#by.Body + 1] = bz
			end
			if a1:IsEof() then
				local bA = {}
				bA.AstType = "Eof"
				bA.Tokens = {a1:Get()}
				by.Body[#by.Body + 1] = bA
			end
			return true, by
		end
		local function bB()
			local bC = ae()
			return ai(bC)
		end
		local n, bD = bB()
		return n, bD
	end
	return {
		LexLua = k,
		ParseLua = a8
	}
end)()
local function fixnum(a)
	a = tostring(tonumber(a))
	local n = a:sub(1, 1) == "-"
	if n then
		a = a:sub(2)
	end
	if a:sub(1, 2) == "0." then
		a = a:sub(2)
	elseif a:match("%d+") == a then
		a = tonumber(a)
		a = a <= 9 and a or ("0x%x"):format(a)
	end
	return n and "-" .. a or a
end
local Legends = {
	["\\"] = "\\\\",
	["\a"] = "\\a",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\v"] = "\\v",
	["\""] = "\\\""
}
local function fixstr(a)
	return "\"" .. (loadstring("return " .. a)():gsub(".", function(x)
		return "\\" .. x:byte()
	end)) .. "\""
end
local FormatBeautiful = (function()
	local a = ParseLua.ParseLua
	local b = Util.lookupify
	local d = b({"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"})
	local e = b({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"})
	local f = b({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"})
	local function g(h, i, ripvon)
		local j, k
		local l, m = 0, "\n"
		local function o(p, q, r)
			r = r or ""
			local s, t = p:sub(-1, -1), q:sub(1, 1)
			if e[s] or d[s] or s == "_" then
				if not (e[t] or d[t] or t == "_" or f[t]) then
					return p .. q
				elseif t == "(" then
					return p .. r .. q
				else
					return p .. r .. q
				end
			elseif f[s] then
				if t == "(" then
					return p .. q
				else
					return p .. r .. q
				end
			elseif s == "" then
				return p .. q
			else
				if t == "(" then
					return p .. r .. q
				else
					return p .. q
				end
			end
		end
		k = function(u)
			local v = ("("):rep(u.ParenCount or 0)
			if u.AstType == "VarExpr" then
				if u.Variable then
					v = v .. u.Variable.Name
				else
					v = v .. u.Name
				end
			elseif u.AstType == "NumberExpr" then
				v = v .. fixnum(u.Value.Data)
			elseif u.AstType == "StringExpr" then
				v = v .. fixstr(u.Value.Data)
			elseif u.AstType == "BooleanExpr" then
				v = v .. tostring(u.Value)
			elseif u.AstType == "NilExpr" then
				v = o(v, "nil")
			elseif u.AstType == "BinopExpr" then
				v = o(v, k(u.Lhs)) .. " "
				v = o(v, u.Op) .. " "
				v = o(v, k(u.Rhs))
			elseif u.AstType == "UnopExpr" then
				v = o(v, u.Op) .. (#u.Op ~= 1 and " " or "")
				v = o(v, k(u.Rhs))
			elseif u.AstType == "DotsExpr" then
				v = v .. "..."
			elseif u.AstType == "CallExpr" then
				v = v .. k(u.Base)
				if ripvon and #u.Arguments == 1 and (u.Arguments[1].AstType == "StringExpr" or u.Arguments[1].AstType == "ConstructorExpr") then
					v = v .. k(u.Arguments[1])
				else
					v = v .. "("
					for i1, v1 in ipairs(u.Arguments) do
						v = v .. k(v1)
						if i1 ~= #u.Arguments then
							v = v .. ", "
						end
					end
					v = v .. ")"
				end
			elseif u.AstType == "TableCallExpr" then
				if ripvon then
					v = v .. k(u.Base) .. k(u.Arguments[1])
				else
					v = v .. k(u.Base) .. "("
					v = v .. k(u.Arguments[1]) .. ")"
				end
			elseif u.AstType == "StringCallExpr" then
				if ripvon then
					v = v .. k(u.Base) .. fixstr(u.Arguments[1].Data)
				else
					v = v .. k(u.Base) .. "("
					v = v .. fixstr(u.Arguments[1].Data) .. ")"
				end
			elseif u.AstType == "IndexExpr" then
				v = v .. k(u.Base) .. "[" .. k(u.Index) .. "]"
			elseif u.AstType == "MemberExpr" then
				v = v .. k(u.Base) .. u.Indexer .. u.Ident.Data
			elseif u.AstType == "Function" then
				v = v .. "function("
				if #u.Arguments > 0 then
				for i1, v1 in ipairs(u.Arguments) do
					v = v .. v1.Name
					if i1 ~= #u.Arguments then
						v = v .. ", "
					elseif u.VarArg then
						v = v .. ", ..."
					end
				end
				elseif u.VarArg then
					v = v .. "..."
				end
				v = v .. ")" .. m
				l = l + 1
				v = o(v, j(u.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif u.AstType == "ConstructorExpr" then
				v = v .. "{"
				local itsanarray = (function()
					for _, v1 in ipairs(u.EntryList) do
						if v1.Type == "Key" or v1.Type == "KeyString" then
							return false
						end
					end
					return true
				end)()
				local x, y, z = false, false, false
				for i1, v1 in ipairs(u.EntryList) do
					x, y = v1.Type == "Key" or v1.Type == "KeyString", x
					l = l + (itsanarray and 0 or 1)
					if x or z then
						z = x
						if not y then
							v = v .. "\n"
						end
						v = v .. ("\t"):rep(l)
					end
					if v1.Type == "Key" then
						v = v .. "[" .. k(v1.Key) .. "] = " .. k(v1.Value)
					elseif v1.Type == "Value" then
						v = v .. k(v1.Value)
					elseif v1.Type == "KeyString" then
						v = v .. v1.Key .. " = " .. k(v1.Value)
					end
					if i1 ~= #u.EntryList then
						v = v .. ","
						if not x then
							v = v .. " "
						end
					end
					if x then
						v = v .. "\n"
					end
					l = l - (itsanarray and 0 or 1)
				end
				if #u.EntryList > 0 and x then
					v = v .. ("\t"):rep(l)
				end
				v = v .. "}"
			elseif u.AstType == "Parentheses" then
				v = v .. "(" .. k(u.Inner) .. ")"
			end
			v = v .. (")"):rep(u.ParenCount or 0)
			return v
		end
		local B = function(C)
			local v = ""
			if C.AstType == "AssignmentStatement" then
				v = ("\t"):rep(l)
				for w = 1, #C.Lhs do
					v = v .. k(C.Lhs[w])
					if w ~= #C.Lhs then
						v = v .. ", "
					end
				end
				if #C.Rhs > 0 then
					v = v .. " = "
					for w = 1, #C.Rhs do
						v = v .. k(C.Rhs[w])
						if w ~= #C.Rhs then
							v = v .. ", "
						end
					end
				end
			elseif C.AstType == "CallStatement" then
				v = ("\t"):rep(l) .. k(C.Expression)
			elseif C.AstType == "LocalStatement" then
				v = ("\t"):rep(l) .. v .. "local "
				for w = 1, #C.LocalList do
					v = v .. C.LocalList[w].Name
					if w ~= #C.LocalList then
						v = v .. ", "
					end
				end
				if #C.InitList > 0 then
					v = v .. " = "
					for w = 1, #C.InitList do
						v = v .. k(C.InitList[w])
						if w ~= #C.InitList then
							v = v .. ", "
						end
					end
				end
			elseif C.AstType == "IfStatement" then
				v = ("\t"):rep(l) .. o("if ", k(C.Clauses[1].Condition))
				v = o(v, " then") .. m
				l = l + 1
				v = o(v, j(C.Clauses[1].Body))
				l = l - 1
				for w = 2, #C.Clauses do
					local D = C.Clauses[w]
					if D.Condition then
						v = o(v, ("\t"):rep(l) .. "elseif ")
						v = o(v, k(D.Condition))
						v = o(v, " then") .. m
					else
						v = o(v, ("\t"):rep(l) .. "else") .. m
					end
					l = l + 1
					v = o(v, j(D.Body))
					l = l - 1
				end
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "WhileStatement" then
				v = ("\t"):rep(l) .. o("while ", k(C.Condition))
				v = o(v, " do") .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "DoStatement" then
				v = ("\t"):rep(l) .. o(v, "do") .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "ReturnStatement" then
				v = ("\t"):rep(l) .. "return "
				for w = 1, #C.Arguments do
					v = o(v, k(C.Arguments[w]))
					if w ~= #C.Arguments then
						v = v .. ", "
					end
				end
			elseif C.AstType == "BreakStatement" then
				v = ("\t"):rep(l) .. "break"
			elseif C.AstType == "ContinueStatement" then
				v = ("\t"):rep(l) .. "continue"
			elseif C.AstType == "RepeatStatement" then
				v = ("\t"):rep(l) .. "repeat" .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "until ")
				v = o(v, k(C.Condition))
			elseif C.AstType == "Function" then
				if C.IsLocal then
					v = "local "
				end
				v = o(v, "function ")
				v = ("\t"):rep(l) .. v
				if C.IsLocal then
					v = v .. C.Name.Name
				else
					v = v .. k(C.Name)
				end
				v = v .. "("
				if #C.Arguments > 0 then
					for w = 1, #C.Arguments do
						v = v .. C.Arguments[w].Name
						if w ~= #C.Arguments then
							v = v .. ", "
						elseif C.VarArg then
							v = v .. ", ..."
						end
					end
				elseif C.VarArg then
					v = v .. "..."
				end
				v = v .. ")" .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "GenericForStatement" then
				v = ("\t"):rep(l) .. "for "
				for w = 1, #C.VariableList do
					v = v .. C.VariableList[w].Name
					if w ~= #C.VariableList then
						v = v .. ", "
					end
				end
				v = v .. " in "
				for w = 1, #C.Generators do
					v = o(v, k(C.Generators[w]))
					if w ~= #C.Generators then
						v = o(v, ", ")
					end
				end
				v = o(v, " do") .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "NumericForStatement" then
				v = ("\t"):rep(l) .. "for "
				v = v .. C.Variable.Name .. " = "
				v = v .. k(C.Start) .. ", " .. k(C.End)
				if C.Step then
					v = v .. ", " .. k(C.Step)
				end
				v = o(v, " do") .. m
				l = l + 1
				v = o(v, j(C.Body))
				l = l - 1
				v = o(v, ("\t"):rep(l) .. "end")
			elseif C.AstType == "LabelStatement" then
				v = ("\t"):rep(l) .. "::" .. C.Label .. "::" .. m
			elseif C.AstType == "GotoStatement" then
				v = ("\t"):rep(l) .. "goto " .. C.Label .. m
			elseif C.AstType == "Comment" then
				if C.CommentType == "Shebang" then
					v = ("\t"):rep(l) .. C.Data
				elseif C.CommentType == "Comment" then
					v = ("\t"):rep(l) .. C.Data
				elseif C.CommentType == "LongComment" then
					v = ("\t"):rep(l) .. C.Data
				end
			elseif C.AstType ~= "Eof" then
				print("Unknown AST Type: ", C.AstType)
			end
			return v
		end
		j = function(E)
			local v = ""
			for F, G in pairs(E.Body) do
				v = o(v, B(G) .. m)
			end
			return v
		end
		if i then
			h.Scope:BeautifyVars()
		end
		return (Util.stripstr(j(h)))
	end
	return g
end)()
local function decrypt(ret)
	local Legends = {
		["\\"] = "\\\\",
		["\a"] = "\\a",
		["\b"] = "\\b",
		["\f"] = "\\f",
		["\n"] = "\\n",
		["\r"] = "\\r",
		["\t"] = "\\t",
		["\v"] = "\\v",
		["\""] = "\\\""
	}
	return (ret:gsub("0x%x+", function(a)
		a = tostring(tonumber(a))
		local n = a:sub(1, 1) == "-"
		if n then
			a = a:sub(2)
		end
		if a:sub(1, 2) == "0." then
			a = a:sub(2)
		elseif a:match("%d+") == a then
			local x = a:match("000+$")
			a = x and (a:sub(1, #a - #x) .. "e" .. #x) or a
		end
		return n and "-" .. a or a
	end):gsub("\"[\\%d+]+\"", function(a)
		return "\"" .. loadstring("return " .. a)():gsub(".", function(x)
			return Legends[x] or x
		end) .. "\""
	end))
end
local function _beautify(scr, encrypt, x)
	local st, ast = ParseLua.ParseLua(scr)
	if not st then
		print(ast)
		return scr
	end
	local ret = FormatBeautiful(ast, false, not not x)
	if not encrypt then
		ret = decrypt(ret)
	end
	return ret:match("^%s*(.-)%s*$")
end
local function _minify(scr, encrypt)
	local ret = _beautify(scr, true, true):gsub("%s+", " "):gsub("([%w_])%s+(%p)", function(a, b)
		if b == "_" then
			return 
		end
		return a .. b
	end):gsub("(%p)%s+([%w_])", function(a, b)
		if a == "_" then
			return 
		end
		return a .. b
	end):gsub("(%p)%s+(%p)", function(a, b)
		if a == "_" or b == "_" then
			return 
		end
		return a .. b
	end)
	if not encrypt then
		ret = decrypt(ret)
	end
	return ret
end
return {
	beautify = _beautify,
	minify = _minify
}
