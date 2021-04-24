local function toDictionary(t)
	for _, v in ipairs(t) do
		t[v] = true
	end
	return t
end
local LettersL = toDictionary({"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"})
local LettersU = toDictionary({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"})
local Numbers = toDictionary({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"})
local NumbersH = toDictionary({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "F", "f"})
local Operators = toDictionary({"+", "-", "*", "/", "^", "%", ",", "{", "}", "[", "]", "(", ")", ";", "#"})
local Keywords = toDictionary({"and", "break", "continue", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"})
local localCount = 0
local getNewLocal = (function()
	local a = {}
	for d = ("a"):byte(), ("z"):byte() do
		a[#a + 1] = string.char(d)
	end
	for e = ("A"):byte(), ("Z"):byte() do
		a[#a + 1] = string.char(e)
	end
	for f = ("0"):byte(), ("9"):byte() do
		a[#a + 1] = string.char(f)
	end
	a[#a + 1] = "_"
	local b = {}
	for g = ("a"):byte(), ("z"):byte() do
		b[#b + 1] = string.char(g)
	end
	for h = ("A"):byte(), ("Z"):byte() do
		b[#b + 1] = string.char(h)
	end
	local function c(i)
		local j = ""
		local k = i % #b
		i = (i - k) / #b
		j = j .. b[k + 1]
		while i > 0 do
			local k = i % #a
			i = (i - k) / #a
			j = j .. a[k + 1]
		end
		return j
	end
	return function()
		local l = ""
		repeat
			local m = localCount
			localCount = localCount + 1
			l = c(m)
		until not Keywords[l]
		return l
	end
end)()
local Scope = {
	new = function(a, b)
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
			__index = a
		})
	end,
	AddLocal = function(e, d)
		table.insert(e.Locals, d)
	end,
	AddGlobal = function(f, g)
		table.insert(f.Globals, g)
	end,
	CreateLocal = function(h, i)
		local j
		j = h:GetLocal(i)
		if j then
			return j
		end
		j = {}
		j.Scope = h
		j.Name = i
		j.IsGlobal = false
		j.CanRename = true
		j.References = 1
		h:AddLocal(j)
		return j
	end,
	GetLocal = function(k, l)
		for m, n in pairs(k.Locals) do
			if n.Name == l then
				return n
			end
		end
		if k.Parent then
			return k.Parent:GetLocal(l)
		end
	end,
	GetOldLocal = function(o, p)
		if o.oldLocalNamesMap[p] then
			return o.oldLocalNamesMap[p]
		end
		return o:GetLocal(p)
	end,
	mapLocal = function(q, r, s)
		q.oldLocalNamesMap[r] = s
	end,
	GetOldGlobal = function(t, u)
		if t.oldGlobalNamesMap[u] then
			return t.oldGlobalNamesMap[u]
		end
		return t:GetGlobal(u)
	end,
	mapGlobal = function(v, w, x)
		v.oldGlobalNamesMap[w] = x
	end,
	GetOldVariable = function(y, z)
		return y:GetOldLocal(z) or y:GetOldGlobal(z)
	end,
	RenameLocal = function(A, B, C)
		B = type(B) == "string" and B or B.Name
		local D = false
		local E = A:GetLocal(B)
		if E then
			E.Name = C
			A:mapLocal(B, E)
			D = true
		end
		if not D and A.Parent then
			A.Parent:RenameLocal(B, C)
		end
	end,
	RenameGlobal = function(F, G, H)
		G = type(G) == "string" and G or G.Name
		local I = false
		local J = F:GetGlobal(G)
		if J then
			J.Name = H
			F:mapGlobal(G, J)
			I = true
		end
		if not I and F.Parent then
			F.Parent:RenameGlobal(G, H)
		end
	end,
	RenameVariable = function(K, L, M)
		L = type(L) == "string" and L or L.Name
		if K:GetLocal(L) then
			K:RenameLocal(L, M)
		else
			K:RenameGlobal(L, M)
		end
	end,
	GetAllVariables = function(N)
		local O = N:getVars(true)
		for P, Q in pairs(N:getVars(false)) do
			table.insert(O, Q)
		end
		return O
	end,
	getVars = function(R, S)
		local T = {}
		if S then
			for U, V in pairs(R.Children) do
				for W, X in pairs(V:getVars(true)) do
					table.insert(T, X)
				end
			end
		else
			for Y, Z in pairs(R.Locals) do
				table.insert(T, Z)
			end
			for ab, bb in pairs(R.Globals) do
				table.insert(T, bb)
			end
			if R.Parent then
				for cb, db in pairs(R.Parent:getVars(false)) do
					table.insert(T, db)
				end
			end
		end
		return T
	end,
	CreateGlobal = function(eb, fb)
		local gb
		gb = eb:GetGlobal(fb)
		if gb then
			return gb
		end
		gb = {}
		gb.Scope = eb
		gb.Name = fb
		gb.IsGlobal = true
		gb.CanRename = true
		gb.References = 1
		eb:AddGlobal(gb)
		return gb
	end,
	GetGlobal = function(hb, ib)
		for jb, kb in pairs(hb.Globals) do
			if kb.Name == ib then
				return kb
			end
		end
		if hb.Parent then
			return hb.Parent:GetGlobal(ib)
		end
	end,
	GetVariable = function(lb, mb)
		return lb:GetLocal(mb) or lb:GetGlobal(mb)
	end,
	ObfuscateLocals = function(nb, ob, pb)
		ob = ob or 7
		local qb = pb or "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuioplkjhgfdsazxcvbnm1234567890"
		for rb, sb in pairs(nb.Locals) do
			local tb = ""
			local ub = 0
			repeat
				local vb = math.random(1, #qb)
				tb = tb .. qb:sub(vb, vb)
				for wb = 1, math.random(0, ub > 5 and 30 or ob) do
					local vb = math.random(1, #qb)
					tb = tb .. qb:sub(vb, vb)
				end
				ub = ub + 1
			until not nb:GetVariable(tb)
			tb = ("."):rep(math.random(20, 50)):gsub(".", function()
				return ({"l", "I"})[math.random(1, 2)]
			end) .. "_" .. tb
			nb:RenameLocal(sb.Name, tb)
		end
	end,
	BeautifyVariables = function(xb, yb)
		for zb, Ab in ipairs(xb.Locals) do
			xb:RenameLocal(Ab, getNewLocal())
		end
	end
}
local function LL(a)
	local b = {}
	local c, d = pcall(function()
		local h = 1
		local i = 1
		local j = 1
		local function k()
			local p = a:sub(h, h)
			if p == "\n" then
				j = 1
				i = i + 1
			else
				j = j + 1
			end
			h = h + 1
			return p
		end
		local function l(q)
			q = q or 0
			return a:sub(h + q, h + q)
		end
		local function m(r)
			local s = l()
			for t = 1, #r do
				if s == r:sub(t, t) then
					return k()
				end
			end
		end
		local function n(u)
			return error(">> :" .. i .. ":" .. j .. ": " .. u, 0)
		end
		local function o()
			local v = h
			if l() == "[" then
				local w = 0
				local x = 1
				while l(w + 1) == "=" do
					w = w + 1
				end
				if l(w + 1) == "[" then
					for B = 0, w + 1 do
						k()
					end
					local y = h
					while true do
						if l() == "" then
							n("Expected `]" .. ("="):rep(w) .. "]` near <eof>.", 3)
						end
						local C = true
						if l() == "]" then
							for D = 1, w do
								if l(D) ~= "=" then
									C = false
								end
							end
							if l(w + 1) ~= "]" then
								C = false
							end
						else
							if l() == "[" then
								local E = true
								for F = 1, w do
									if l(F) ~= "=" then
										E = false
										break
									end
								end
								if l(w + 1) == "[" and E then
									x = x + 1
									for G = 1, w + 2 do
										k()
									end
								end
							end
							C = false
						end
						if C then
							x = x - 1
							if x == 0 then
								break
							else
								for H = 1, w + 2 do
									k()
								end
							end
						else
							k()
						end
					end
					local z = a:sub(y, h - 1)
					for I = 0, w + 1 do
						k()
					end
					local A = a:sub(v, h - 1)
					return z, A
				else
					return nil
				end
			else
				return nil
			end
		end
		while true do
			local J = {}
			local K = ""
			local L = false
			while true do
				local R = l()
				if R == "#" and l(1) == "!" and i == 1 then
					k()
					k()
					K = "#!"
					while l() ~= "\n" and l() ~= "" do
						K = K .. k()
					end
					local S = {
						Type = "Comment",
						CommentType = "Shebang",
						Data = K,
						Line = i,
						Char = j
					}
					S.Print = function()
						return "<" .. (S.Type .. (" "):rep(7 - #S.Type)) .. "  " .. (S.Data or "") .. " >"
					end
					K = ""
					table.insert(J, S)
				end
				if R == " " or R == "\t" then
					local T = k()
					table.insert(J, {
						Type = "Whitespace",
						Line = i,
						Char = j,
						Data = T
					})
				elseif R == "\n" or R == "\r" then
					local U = k()
					if K ~= "" then
						local V = {
							Type = "Comment",
							CommentType = L and "LongComment" or "Comment",
							Data = K,
							Line = i,
							Char = j
						}
						V.Print = function()
							return "<" .. (V.Type .. (" "):rep(7 - #V.Type)) .. "  " .. (V.Data or "") .. " >"
						end
						table.insert(J, V)
						K = ""
					end
					table.insert(J, {
						Type = "Whitespace",
						Line = i,
						Char = j,
						Data = U
					})
				elseif R == "-" and l(1) == "-" then
					k()
					k()
					K = K .. "--"
					local W, X = o()
					if X then
						K = K .. X
						L = true
					else
						while l() ~= "\n" and l() ~= "" do
							K = K .. k()
						end
					end
				else
					break
				end
			end
			if K ~= "" then
				local Y = {
					Type = "Comment",
					CommentType = L and "LongComment" or "Comment",
					Data = K,
					Line = i,
					Char = j
				}
				Y.Print = function()
					return "<" .. (Y.Type .. (" "):rep(7 - #Y.Type)) .. "  " .. (Y.Data or "") .. " >"
				end
				table.insert(J, Y)
			end
			local M = i
			local N = j
			local O = ":" .. i .. ":" .. j .. ":> "
			local P = l()
			local Q = nil
			if P == "" then
				Q = {
					Type = "Eof"
				}
			elseif LettersU[P] or LettersL[P] or P == "_" then
				local Z = h
				repeat
					k()
					P = l()
				until not (LettersU[P] or LettersL[P] or Numbers[P] or P == "_")
				local ab = a:sub(Z, h - 1)
				if Keywords[ab] then
					Q = {
						Type = "Keyword",
						Data = ab
					}
				else
					Q = {
						Type = "Ident",
						Data = ab
					}
				end
			elseif Numbers[P] or l() == "." and Numbers[l(1)] then
				local bb = h
				if P == "0" and l(1):lower() == "x" then
					k()
					k()
					while NumbersH[l()] do
						k()
					end
					if m("Pp") then
						m("+-")
						while Numbers[l()] do
							k()
						end
					end
				else
					while Numbers[l()] do
						k()
					end
					if m(".") then
						while Numbers[l()] do
							k()
						end
					end
					if m("Ee") then
						m("+-")
						while Numbers[l()] do
							k()
						end
					end
				end
				Q = {
					Type = "Number",
					Data = a:sub(bb, h - 1)
				}
			elseif P == "'" or P == "\"" then
				local cb = h
				local db = k()
				local eb = h
				while true do
					local P = k()
					if P == "\\" then
						k()
					elseif P == db then
						break
					elseif P == "" then
						n("Unfinished string near <eof>")
					end
				end
				local fb = a:sub(eb, h - 2)
				local gb = a:sub(cb, h - 1)
				Q = {
					Type = "string",
					Data = gb,
					Constant = fb
				}
			elseif P == "[" then
				local hb, ib = o()
				if ib then
					Q = {
						Type = "string",
						Data = ib,
						Constant = hb
					}
				else
					k()
					Q = {
						Type = "Symbol",
						Data = "["
					}
				end
			elseif m(">=<") then
				if m("=") then
					Q = {
						Type = "Symbol",
						Data = P .. "="
					}
				else
					Q = {
						Type = "Symbol",
						Data = P
					}
				end
			elseif m("~") then
				if m("=") then
					Q = {
						Type = "Symbol",
						Data = "~="
					}
				else
					n("Unexpected symbol `~` in source.", 2)
				end
			elseif m(".") then
				if m(".") then
					if m(".") then
						Q = {
							Type = "Symbol",
							Data = "..."
						}
					else
						Q = {
							Type = "Symbol",
							Data = ".."
						}
					end
				else
					Q = {
						Type = "Symbol",
						Data = "."
					}
				end
			elseif m(":") then
				if m(":") then
					Q = {
						Type = "Symbol",
						Data = "::"
					}
				else
					Q = {
						Type = "Symbol",
						Data = ":"
					}
				end
			elseif Operators[P] then
				k()
				Q = {
					Type = "Symbol",
					Data = P
				}
			else
				local jb, kb = o()
				if jb then
					Q = {
						Type = "string",
						Data = kb,
						Constant = jb
					}
				else
					n("Unexpected Symbol `" .. P .. "` in source.", 2)
				end
			end
			Q.LeadingWhite = J
			Q.Line = M
			Q.Char = N
			Q.Print = function()
				return "<" .. (Q.Type .. (" "):rep(7 - #Q.Type)) .. "  " .. (Q.Data or "") .. " >"
			end
			b[#b + 1] = Q
			if Q.Type == "Eof" then
				break
			end
		end
	end)
	if not c then
		return false, d
	end
	local e = {}
	local f = {}
	local g = 1
	function e:getp()
		return g
	end
	function e:setp(lb)
		g = lb
	end
	function e:getTokenList()
		return b
	end
	function e:Peek(mb)
		mb = mb or 0
		return b[math.min(#b, g + mb)]
	end
	function e:Get(nb)
		local ob = b[g]
		g = math.min(g + 1, #b)
		if nb then
			table.insert(nb, ob)
		end
		return ob
	end
	function e:Is(pb)
		return e:Peek().Type == pb
	end
	function e:Save()
		f[#f + 1] = g
	end
	function e:Commit()
		f[#f] = nil
	end
	function e:Restore()
		g = f[#f]
		f[#f] = nil
	end
	function e:ConsumeSymbol(qb, rb)
		local sb = self:Peek()
		if sb.Type == "Symbol" then
			if qb then
				if sb.Data == qb then
					self:Get(rb)
					return true
				else
					return nil
				end
			else
				self:Get(rb)
				return sb
			end
		else
			return nil
		end
	end
	function e:ConsumeKeyword(tb, ub)
		local vb = self:Peek()
		if vb.Type == "Keyword" and vb.Data == tb then
			self:Get(ub)
			return true
		else
			return nil
		end
	end
	function e:IsKeyword(wb)
		local xb = e:Peek()
		return xb.Type == "Keyword" and xb.Data == wb
	end
	function e:IsSymbol(yb)
		local zb = e:Peek()
		return zb.Type == "Symbol" and zb.Data == yb
	end
	function e:IsEof()
		return e:Peek().Type == "Eof"
	end
	return true, e
end
local function ParseLua(a)
	local b, c
	if type(a) ~= "table" then
		b, c = LL(a)
	else
		b, c = true, a
	end
	if not b then
		return false, c
	end
	local function d(v)
		local w = ">> :" .. c:Peek().Line .. ":" .. c:Peek().Char .. ": " .. v .. "\n"
		local x = 0
		if type(a) == "string" then
			for y in a:gmatch("[^\n]*\n?") do
				if y:sub(-1, -1) == "\n" then
					y = y:sub(1, -2)
				end
				x = x + 1
				if x == c:Peek().Line then
					w = w .. ">> `" .. y:gsub("\t", "\t") .. "`\n"
					for z = 1, c:Peek().Char do
						local A = y:sub(z, z)
						if A == "\t" then
							w = w .. "\t"
						else
							w = w .. " "
						end
					end
					w = w .. "   ^^^^"
					break
				end
			end
		end
		return w
	end
	local e = 0
	local f = {"_", "a", "b", "c", "d"}
	local function g(B)
		local C = Scope:new(B)
		C.RenameVars = C.ObfuscateLocals
		C.ObfuscateVariables = C.ObfuscateLocals
		C.BeautifyVars = C.BeautifyVariables
		C.Print = function()
			return "<Scope>"
		end
		return C
	end
	local h
	local i
	local j, k, l, m
	local function n(D, E)
		local F = g(D)
		if not c:ConsumeSymbol("(", E) then
			return false, d("`(` expected.")
		end
		local G = {}
		local H = false
		while not c:ConsumeSymbol(")", E) do
			if c:Is("Ident") then
				local K = F:CreateLocal(c:Get(E).Data)
				G[#G + 1] = K
				if not c:ConsumeSymbol(",", E) then
					if c:ConsumeSymbol(")", E) then
						break
					else
						return false, d("`)` expected.")
					end
				end
			elseif c:ConsumeSymbol("...", E) then
				H = true
				if not c:ConsumeSymbol(")", E) then
					return false, d("`...` must be the last argument of a function.")
				end
				break
			else
				return false, d("Argument name or `...` expected")
			end
		end
		local b, I = i(F)
		if not b then
			return false, I
		end
		if not c:ConsumeKeyword("end", E) then
			return false, d("`end` expected after function body")
		end
		local J = {}
		J.AstType = "Function"
		J.Scope = F
		J.Arguments = G
		J.Body = I
		J.VarArg = H
		J.Tokens = E
		return true, J
	end
	function l(L)
		local M = {}
		if c:ConsumeSymbol("(", M) then
			local b, N = h(L)
			if not b then
				return false, N
			end
			if not c:ConsumeSymbol(")", M) then
				return false, d("`)` Expected.")
			end
			if false then
				N.ParenCount = (N.ParenCount or 0) + 1
				return true, N
			else
				local O = {}
				O.AstType = "Parentheses"
				O.Inner = N
				O.Tokens = M
				return true, O
			end
		elseif c:Is("Ident") then
			local P = c:Get(M)
			local Q = L:GetLocal(P.Data)
			if not Q then
				Q = L:GetGlobal(P.Data)
				if not Q then
					Q = L:CreateGlobal(P.Data)
				else
					Q.References = Q.References + 1
				end
			else
				Q.References = Q.References + 1
			end
			local R = {}
			R.AstType = "VarExpr"
			R.Name = P.Data
			R.Variable = Q
			R.Tokens = M
			return true, R
		else
			return false, d("primary expression expected")
		end
	end
	function m(S, T)
		local b, U = l(S)
		if not b then
			return false, U
		end
		while true do
			local V = {}
			if c:IsSymbol(".") or c:IsSymbol(":") then
				local W = c:Get(V).Data
				if not c:Is("Ident") then
					return false, d("<Ident> expected.")
				end
				local X = c:Get(V)
				local Y = {}
				Y.AstType = "MemberExpr"
				Y.Base = U
				Y.Indexer = W
				Y.Ident = X
				Y.Tokens = V
				U = Y
			elseif not T and c:ConsumeSymbol("[", V) then
				local b, Z = h(S)
				if not b then
					return false, Z
				end
				if not c:ConsumeSymbol("]", V) then
					return false, d("`]` expected.")
				end
				local ab = {}
				ab.AstType = "IndexExpr"
				ab.Base = U
				ab.Index = Z
				ab.Tokens = V
				U = ab
			elseif not T and c:ConsumeSymbol("(", V) then
				local bb = {}
				while not c:ConsumeSymbol(")", V) do
					local b, db = h(S)
					if not b then
						return false, db
					end
					bb[#bb + 1] = db
					if not c:ConsumeSymbol(",", V) then
						if c:ConsumeSymbol(")", V) then
							break
						else
							return false, d("`)` Expected.")
						end
					end
				end
				local cb = {}
				cb.AstType = "CallExpr"
				cb.Base = U
				cb.Arguments = bb
				cb.Tokens = V
				U = cb
			elseif not T and c:Is("string") then
				local eb = {}
				eb.AstType = "StringCallExpr"
				eb.Base = U
				eb.Arguments = {c:Get(V)}
				eb.Tokens = V
				U = eb
			elseif not T and c:IsSymbol("{") then
				local b, fb = j(S)
				if not b then
					return false, fb
				end
				local gb = {}
				gb.AstType = "TableCallExpr"
				gb.Base = U
				gb.Arguments = {fb}
				gb.Tokens = V
				U = gb
			else
				break
			end
		end
		return true, U
	end
	function j(hb)
		local ib = {}
		if c:Is("Number") then
			local jb = {}
			jb.AstType = "NumberExpr"
			jb.Value = c:Get(ib)
			jb.Tokens = ib
			return true, jb
		elseif c:Is("string") then
			local kb = {}
			kb.AstType = "StringExpr"
			kb.Value = c:Get(ib)
			kb.Tokens = ib
			return true, kb
		elseif c:ConsumeKeyword("nil", ib) then
			local lb = {}
			lb.AstType = "NilExpr"
			lb.Tokens = ib
			return true, lb
		elseif c:IsKeyword("false") or c:IsKeyword("true") then
			local mb = {}
			mb.AstType = "BooleanExpr"
			mb.Value = c:Get(ib).Data == "true"
			mb.Tokens = ib
			return true, mb
		elseif c:ConsumeSymbol("...", ib) then
			local nb = {}
			nb.AstType = "DotsExpr"
			nb.Tokens = ib
			return true, nb
		elseif c:ConsumeSymbol("{", ib) then
			local ob = {}
			ob.AstType = "ConstructorExpr"
			ob.EntryList = {}
			while true do
				if c:IsSymbol("[", ib) then
					c:Get(ib)
					local b, pb = h(hb)
					if not b then
						return false, d("Key Expression Expected")
					end
					if not c:ConsumeSymbol("]", ib) then
						return false, d("`]` Expected")
					end
					if not c:ConsumeSymbol("=", ib) then
						return false, d("`=` Expected")
					end
					local b, qb = h(hb)
					if not b then
						return false, d("Value Expression Expected")
					end
					ob.EntryList[#ob.EntryList + 1] = {
						Type = "Key",
						Key = pb,
						Value = qb
					}
				elseif c:Is("Ident") then
					local rb = c:Peek(1)
					if rb.Type == "Symbol" and rb.Data == "=" then
						local sb = c:Get(ib)
						if not c:ConsumeSymbol("=", ib) then
							return false, d("`=` Expected")
						end
						local b, tb = h(hb)
						if not b then
							return false, d("Value Expression Expected")
						end
						ob.EntryList[#ob.EntryList + 1] = {
							Type = "KeyString",
							Key = sb.Data,
							Value = tb
						}
					else
						local b, ub = h(hb)
						if not b then
							return false, d("Value Exected")
						end
						ob.EntryList[#ob.EntryList + 1] = {
							Type = "Value",
							Value = ub
						}
					end
				elseif c:ConsumeSymbol("}", ib) then
					break
				else
					local b, vb = h(hb)
					ob.EntryList[#ob.EntryList + 1] = {
						Type = "Value",
						Value = vb
					}
					if not b then
						return false, d("Value Expected")
					end
				end
				if c:ConsumeSymbol(";", ib) or c:ConsumeSymbol(",", ib) then
				elseif c:ConsumeSymbol("}", ib) then
					break
				else
					return false, d("`}` or table entry Expected")
				end
			end
			ob.Tokens = ib
			return true, ob
		elseif c:ConsumeKeyword("function", ib) then
			local b, wb = n(hb, ib)
			if not b then
				return false, wb
			end
			wb.IsLocal = true
			return true, wb
		else
			return m(hb)
		end
	end
	local o = toDictionary({"-", "not", "#"})
	local p = 8
	local q = {
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
	function k(xb, yb)
		local b, zb
		if o[c:Peek().Data] then
			local Ab = {}
			local Bb = c:Get(Ab).Data
			b, zb = k(xb, p)
			if not b then
				return false, zb
			end
			local Cb = {}
			Cb.AstType = "UnopExpr"
			Cb.Rhs = zb
			Cb.Op = Bb
			Cb.OperatorPrecedence = p
			Cb.Tokens = Ab
			zb = Cb
		else
			b, zb = j(xb)
			if not b then
				return false, zb
			end
		end
		while true do
			local Db = q[c:Peek().Data]
			if Db and Db[1] > yb then
				local Eb = {}
				local Fb = c:Get(Eb).Data
				local b, Gb = k(xb, Db[2])
				if not b then
					return false, Gb
				end
				local Hb = {}
				Hb.AstType = "BinopExpr"
				Hb.Lhs = zb
				Hb.Op = Fb
				Hb.OperatorPrecedence = Db[1]
				Hb.Rhs = Gb
				Hb.Tokens = Eb
				zb = Hb
			else
				break
			end
		end
		return true, zb
	end
	h = function(Ib)
		return k(Ib, 0)
	end
	local function r(Jb)
		local Kb = nil
		local Lb = {}
		if c:ConsumeKeyword("if", Lb) then
			local Mb = {}
			Mb.AstType = "IfStatement"
			Mb.Clauses = {}
			repeat
				local b, Nb = h(Jb)
				if not b then
					return false, Nb
				end
				if not c:ConsumeKeyword("then", Lb) then
					return false, d("`then` expected.")
				end
				local b, Ob = i(Jb)
				if not b then
					return false, Ob
				end
				Mb.Clauses[#Mb.Clauses + 1] = {
					Condition = Nb,
					Body = Ob
				}
			until not c:ConsumeKeyword("elseif", Lb)
			if c:ConsumeKeyword("else", Lb) then
				local b, Pb = i(Jb)
				if not b then
					return false, Pb
				end
				Mb.Clauses[#Mb.Clauses + 1] = {
					Body = Pb
				}
			end
			if not c:ConsumeKeyword("end", Lb) then
				return false, d("`end` expected.")
			end
			Mb.Tokens = Lb
			Kb = Mb
		elseif c:ConsumeKeyword("while", Lb) then
			local Qb = {}
			Qb.AstType = "WhileStatement"
			local b, Rb = h(Jb)
			if not b then
				return false, Rb
			end
			if not c:ConsumeKeyword("do", Lb) then
				return false, d("`do` expected.")
			end
			local b, Sb = i(Jb)
			if not b then
				return false, Sb
			end
			if not c:ConsumeKeyword("end", Lb) then
				return false, d("`end` expected.")
			end
			Qb.Condition = Rb
			Qb.Body = Sb
			Qb.Tokens = Lb
			Kb = Qb
		elseif c:ConsumeKeyword("do", Lb) then
			local b, Tb = i(Jb)
			if not b then
				return false, Tb
			end
			if not c:ConsumeKeyword("end", Lb) then
				return false, d("`end` expected.")
			end
			local Ub = {}
			Ub.AstType = "DoStatement"
			Ub.Body = Tb
			Ub.Tokens = Lb
			Kb = Ub
		elseif c:ConsumeKeyword("for", Lb) then
			if not c:Is("Ident") then
				return false, d("<ident> expected.")
			end
			local Vb = c:Get(Lb)
			if c:ConsumeSymbol("=", Lb) then
				local Wb = g(Jb)
				local Xb = Wb:CreateLocal(Vb.Data)
				local b, Yb = h(Jb)
				if not b then
					return false, Yb
				end
				if not c:ConsumeSymbol(",", Lb) then
					return false, d("`,` Expected")
				end
				local b, Zb = h(Jb)
				if not b then
					return false, Zb
				end
				local b, ac
				if c:ConsumeSymbol(",", Lb) then
					b, ac = h(Jb)
					if not b then
						return false, ac
					end
				end
				if not c:ConsumeKeyword("do", Lb) then
					return false, d("`do` expected")
				end
				local b, bc = i(Wb)
				if not b then
					return false, bc
				end
				if not c:ConsumeKeyword("end", Lb) then
					return false, d("`end` expected")
				end
				local cc = {}
				cc.AstType = "NumericForStatement"
				cc.Scope = Wb
				cc.Variable = Xb
				cc.Start = Yb
				cc.End = Zb
				cc.Step = ac
				cc.Body = bc
				cc.Tokens = Lb
				Kb = cc
			else
				local dc = g(Jb)
				local ec = {dc:CreateLocal(Vb.Data)}
				while c:ConsumeSymbol(",", Lb) do
					if not c:Is("Ident") then
						return false, d("for variable expected.")
					end
					ec[#ec + 1] = dc:CreateLocal(c:Get(Lb).Data)
				end
				if not c:ConsumeKeyword("in", Lb) then
					return false, d("`in` expected.")
				end
				local fc = {}
				local b, gc = h(Jb)
				if not b then
					return false, gc
				end
				fc[#fc + 1] = gc
				while c:ConsumeSymbol(",", Lb) do
					local b, jc = h(Jb)
					if not b then
						return false, jc
					end
					fc[#fc + 1] = jc
				end
				if not c:ConsumeKeyword("do", Lb) then
					return false, d("`do` expected.")
				end
				local b, hc = i(dc)
				if not b then
					return false, hc
				end
				if not c:ConsumeKeyword("end", Lb) then
					return false, d("`end` expected.")
				end
				local ic = {}
				ic.AstType = "GenericForStatement"
				ic.Scope = dc
				ic.VariableList = ec
				ic.Generators = fc
				ic.Body = hc
				ic.Tokens = Lb
				Kb = ic
			end
		elseif c:ConsumeKeyword("repeat", Lb) then
			local b, kc = i(Jb)
			if not b then
				return false, kc
			end
			if not c:ConsumeKeyword("until", Lb) then
				return false, d("`until` expected.")
			end
			local b, lc = h(kc.Scope)
			if not b then
				return false, lc
			end
			local mc = {}
			mc.AstType = "RepeatStatement"
			mc.Condition = lc
			mc.Body = kc
			mc.Tokens = Lb
			Kb = mc
		elseif c:ConsumeKeyword("function", Lb) then
			if not c:Is("Ident") then
				return false, d("Function name expected")
			end
			local b, nc = m(Jb, true)
			if not b then
				return false, nc
			end
			local b, oc = n(Jb, Lb)
			if not b then
				return false, oc
			end
			oc.IsLocal = false
			oc.Name = nc
			Kb = oc
		elseif c:ConsumeKeyword("local", Lb) then
			if c:Is("Ident") then
				local pc = {c:Get(Lb).Data}
				while c:ConsumeSymbol(",", Lb) do
					if not c:Is("Ident") then
						return false, d("local var name expected")
					end
					pc[#pc + 1] = c:Get(Lb).Data
				end
				local qc = {}
				if c:ConsumeSymbol("=", Lb) then
					repeat
						local b, sc = h(Jb)
						if not b then
							return false, sc
						end
						qc[#qc + 1] = sc
					until not c:ConsumeSymbol(",", Lb)
				end
				for tc, uc in pairs(pc) do
					pc[tc] = Jb:CreateLocal(uc)
				end
				local rc = {}
				rc.AstType = "LocalStatement"
				rc.LocalList = pc
				rc.InitList = qc
				rc.Tokens = Lb
				Kb = rc
			elseif c:ConsumeKeyword("function", Lb) then
				if not c:Is("Ident") then
					return false, d("Function name expected")
				end
				local vc = c:Get(Lb).Data
				local wc = Jb:CreateLocal(vc)
				local b, xc = n(Jb, Lb)
				if not b then
					return false, xc
				end
				xc.Name = wc
				xc.IsLocal = true
				Kb = xc
			else
				return false, d("local var or function def expected")
			end
		elseif c:ConsumeSymbol("::", Lb) then
			if not c:Is("Ident") then
				return false, d("Label name expected")
			end
			local yc = c:Get(Lb).Data
			if not c:ConsumeSymbol("::", Lb) then
				return false, d("`::` expected")
			end
			local zc = {}
			zc.AstType = "LabelStatement"
			zc.Label = yc
			zc.Tokens = Lb
			Kb = zc
		elseif c:ConsumeKeyword("return", Lb) then
			local Ac = {}
			if not c:IsKeyword("end") then
				local b, Cc = h(Jb)
				if b then
					Ac[1] = Cc
					while c:ConsumeSymbol(",", Lb) do
						local b, Dc = h(Jb)
						if not b then
							return false, Dc
						end
						Ac[#Ac + 1] = Dc
					end
				end
			end
			local Bc = {}
			Bc.AstType = "ReturnStatement"
			Bc.Arguments = Ac
			Bc.Tokens = Lb
			Kb = Bc
		elseif c:ConsumeKeyword("break", Lb) then
			local Ec = {}
			Ec.AstType = "BreakStatement"
			Ec.Tokens = Lb
			Kb = Ec
		elseif c:ConsumeKeyword("continue", Lb) then
			local Fc = {}
			Fc.AstType = "ContinueStatement"
			Fc.Tokens = Lb
			Kb = Fc
		else
			local b, Gc = m(Jb)
			if not b then
				return false, Gc
			end
			if c:IsSymbol(",") or c:IsSymbol("=") then
				if (Gc.ParenCount or 0) > 0 then
					return false, d("Can not assign to parenthesized expression, is not an lvalue")
				end
				local Hc = {Gc}
				while c:ConsumeSymbol(",", Lb) do
					local b, Lc = m(Jb)
					if not b then
						return false, Lc
					end
					Hc[#Hc + 1] = Lc
				end
				if not c:ConsumeSymbol("=", Lb) then
					return false, d("`=` Expected.")
				end
				local Ic = {}
				local b, Jc = h(Jb)
				if not b then
					return false, Jc
				end
				Ic[1] = Jc
				while c:ConsumeSymbol(",", Lb) do
					local b, Mc = h(Jb)
					if not b then
						return false, Mc
					end
					Ic[#Ic + 1] = Mc
				end
				local Kc = {}
				Kc.AstType = "AssignmentStatement"
				Kc.Lhs = Hc
				Kc.Rhs = Ic
				Kc.Tokens = Lb
				Kb = Kc
			elseif Gc.AstType == "CallExpr" or Gc.AstType == "TableCallExpr" or Gc.AstType == "StringCallExpr" then
				local Nc = {}
				Nc.AstType = "CallStatement"
				Nc.Expression = Gc
				Nc.Tokens = Lb
				Kb = Nc
			else
				return false, d("Assignment Statement Expected")
			end
		end
		if c:IsSymbol(";") then
			Kb.Semicolon = c:Get(Kb.Tokens)
		end
		return true, Kb
	end
	local s = toDictionary({"end", "else", "elseif", "until"})
	i = function(Oc)
		local Pc = {}
		Pc.Scope = g(Oc)
		Pc.AstType = "Statlist"
		Pc.Body = {}
		Pc.Tokens = {}
		while not s[c:Peek().Data] and not c:IsEof() do
			local b, Qc = r(Pc.Scope)
			if not b then
				return false, Qc
			end
			Pc.Body[#Pc.Body + 1] = Qc
		end
		if c:IsEof() then
			local Rc = {}
			Rc.AstType = "Eof"
			Rc.Tokens = {c:Get()}
			Pc.Body[#Pc.Body + 1] = Rc
		end
		return true, Pc
	end
	local function t()
		local Sc = g()
		return i(Sc)
	end
	local b, u = t()
	return b, u
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
local function fixnum(a, c)
	a = tostring(tonumber(a))
	local b = a:sub(1, 1) == "-"
	if b then
		a = a:sub(2)
	end
	if a:sub(1, 2) == "0." then
		a = a:sub(2)
	elseif a:match("%d+") == a then
		if c then
			a = tonumber(a)
			a = a <= 1 and a or ("0x%x"):format(a)
		else
			local x = a:match("000+$")
			a = x and (a:sub(1, #a - #x) .. "e" .. #x) or a
		end
	end
	return b and "-" .. a or a
end
local function fixstr(a)
	return "\"" .. (loadstring("return " .. a)():gsub(".", function(b)
		return "\\" .. b:byte()
	end)) .. "\""
end
local function Format(a, b, c, d)
	localCount = 0
	local l, i, j, k = 0, "\n", false, false
	local function f(o, m, n)
		n = n or ""
		local q, p = o:sub(-1, -1), m:sub(1, 1)
		if LettersU[q] or LettersL[q] or q == "_" then
			if not (LettersU[p] or LettersL[p] or p == "_" or Numbers[p]) then
				return o .. m
			elseif p == "(" then
				return o .. n .. m
			else
				return o .. n .. m
			end
		elseif Numbers[q] then
			if p == "(" then
				return o .. m
			else
				return o .. n .. m
			end
		elseif q == "" then
			return o .. m
		else
			if p == "(" then
				return o .. n .. m
			else
				return o .. m
			end
		end
	end
	local g = {}
	local function h(r)
		if b and not g[r] then
			g[r] = true
			r.Scope:BeautifyVars()
		end
	end
	local function e(s)
		if b and s.Scope then
			h(s)
		end
		local t = ("("):rep(s.ParenCount or 0)
		if s.AstType == "VarExpr" then
			if s.Variable then
				t = t .. s.Variable.Name
			else
				t = t .. s.Name
			end
		elseif s.AstType == "NumberExpr" then
			t = t .. fixnum(s.Value.Data, d)
		elseif s.AstType == "StringExpr" then
			t = t .. fixstr(s.Value.Data)
		elseif s.AstType == "BooleanExpr" then
			t = t .. tostring(s.Value)
		elseif s.AstType == "NilExpr" then
			t = f(t, "nil")
		elseif s.AstType == "BinopExpr" then
			t = f(t, e(s.Lhs)) .. " "
			t = f(t, s.Op) .. " "
			t = f(t, e(s.Rhs))
		elseif s.AstType == "UnopExpr" then
			t = f(t, s.Op) .. (#s.Op ~= 1 and " " or "")
			t = f(t, e(s.Rhs))
		elseif s.AstType == "DotsExpr" then
			t = t .. "..."
		elseif s.AstType == "CallExpr" then
			t = t .. e(s.Base)
			if c and #s.Arguments == 1 and (s.Arguments[1].AstType == "StringExpr" or s.Arguments[1].AstType == "ConstructorExpr") then
				t = t .. e(s.Arguments[1])
			else
				t = t .. "("
				for v, u in ipairs(s.Arguments) do
					t = t .. e(u)
					if v ~= #s.Arguments then
						t = t .. ", "
					end
				end
				t = t .. ")"
			end
		elseif s.AstType == "TableCallExpr" then
			if c then
				t = t .. e(s.Base) .. e(s.Arguments[1])
			else
				t = t .. e(s.Base) .. "("
				t = t .. e(s.Arguments[1]) .. ")"
			end
		elseif s.AstType == "StringCallExpr" then
			if c then
				t = t .. e(s.Base) .. fixstr(s.Arguments[1].Data)
			else
				t = t .. e(s.Base) .. "("
				t = t .. fixstr(s.Arguments[1].Data) .. ")"
			end
		elseif s.AstType == "IndexExpr" then
			t = t .. e(s.Base) .. "[" .. e(s.Index) .. "]"
		elseif s.AstType == "MemberExpr" then
			t = t .. e(s.Base) .. s.Indexer .. s.Ident.Data
		elseif s.AstType == "Function" then
			t = t .. "function("
			if #s.Arguments > 0 then
				for x, w in ipairs(s.Arguments) do
					t = t .. w.Name
					if x ~= #s.Arguments then
						t = t .. ", "
					elseif s.VarArg then
						t = t .. ", ..."
					end
				end
			elseif s.VarArg then
				t = t .. "..."
			end
			t = t .. ")" .. i
			l = l + 1
			t = f(t, j(s.Body))
			l = l - 1
			t = f(t, ("\t"):rep(l) .. "end")
		elseif s.AstType == "ConstructorExpr" then
			t = t .. "{"
			local A = (function()
				for D, C in ipairs(s.EntryList) do
					if C.Type == "Key" or C.Type == "KeyString" then
						return false
					end
				end
				return true
			end)()
			local B, y, z = false, false, false
			for F, E in ipairs(s.EntryList) do
				B, y = E.Type == "Key" or E.Type == "KeyString", B
				l = l + (A and 0 or 1)
				if B or z then
					z = B
					if not y then
						t = t .. "\n"
					end
					t = t .. ("\t"):rep(l)
				end
				if E.Type == "Key" then
					t = t .. "[" .. e(E.Key) .. "] = " .. e(E.Value)
				elseif E.Type == "Value" then
					t = t .. e(E.Value)
				elseif E.Type == "KeyString" then
					t = t .. E.Key .. " = " .. e(E.Value)
				end
				if F ~= #s.EntryList then
					t = t .. ","
					if not B then
						t = t .. " "
					end
				end
				if B then
					t = t .. "\n"
				end
				l = l - (A and 0 or 1)
			end
			if #s.EntryList > 0 and B then
				t = t .. ("\t"):rep(l)
			end
			t = t .. "}"
		elseif s.AstType == "Parentheses" then
			local G = 0
			local f = false
			repeat
				f = (f or s).Inner
				G = G + 1
			until f.AstType ~= "Parentheses"
			t = t .. (G >= 2 and "((" or "(") .. e(f) .. (G >= 2 and "))" or ")")
		end
		t = t .. (")"):rep(s.ParenCount or 0)
		return t
	end
	function k(H)
		if b and H.Scope then
			h(H)
		end
		local I = ""
		if H.AstType == "AssignmentStatement" then
			I = ("\t"):rep(l)
			for J = 1, #H.Lhs do
				I = I .. e(H.Lhs[J])
				if J ~= #H.Lhs then
					I = I .. ", "
				end
			end
			if #H.Rhs > 0 then
				I = I .. " = "
				for K = 1, #H.Rhs do
					I = I .. e(H.Rhs[K])
					if K ~= #H.Rhs then
						I = I .. ", "
					end
				end
			end
		elseif H.AstType == "CallStatement" then
			I = ("\t"):rep(l) .. e(H.Expression)
		elseif H.AstType == "LocalStatement" then
			I = ("\t"):rep(l) .. I .. "local "
			for L = 1, #H.LocalList do
				I = I .. H.LocalList[L].Name
				if L ~= #H.LocalList then
					I = I .. ", "
				end
			end
			if #H.InitList > 0 then
				I = I .. " = "
				for M = 1, #H.InitList do
					I = I .. e(H.InitList[M])
					if M ~= #H.InitList then
						I = I .. ", "
					end
				end
			end
		elseif H.AstType == "IfStatement" then
			I = ("\t"):rep(l) .. f("if ", e(H.Clauses[1].Condition))
			I = f(I, " then") .. i
			l = l + 1
			I = f(I, j(H.Clauses[1].Body))
			l = l - 1
			for N = 2, #H.Clauses do
				local O = H.Clauses[N]
				if O.Condition then
					I = f(I, ("\t"):rep(l) .. "elseif ")
					I = f(I, e(O.Condition))
					I = f(I, " then") .. i
				else
					I = f(I, ("\t"):rep(l) .. "else") .. i
				end
				l = l + 1
				I = f(I, j(O.Body))
				l = l - 1
			end
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "WhileStatement" then
			I = ("\t"):rep(l) .. f("while ", e(H.Condition))
			I = f(I, " do") .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "DoStatement" then
			I = ("\t"):rep(l) .. f(I, "do") .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "ReturnStatement" then
			I = ("\t"):rep(l) .. "return "
			for P = 1, #H.Arguments do
				I = f(I, e(H.Arguments[P]))
				if P ~= #H.Arguments then
					I = I .. ", "
				end
			end
		elseif H.AstType == "BreakStatement" then
			I = ("\t"):rep(l) .. "break"
		elseif H.AstType == "ContinueStatement" then
			I = ("\t"):rep(l) .. "continue"
		elseif H.AstType == "RepeatStatement" then
			I = ("\t"):rep(l) .. "repeat" .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "until ")
			I = f(I, e(H.Condition))
		elseif H.AstType == "Function" then
			if H.IsLocal then
				I = "local "
			end
			I = f(I, "function ")
			I = ("\t"):rep(l) .. I
			if H.IsLocal then
				I = I .. H.Name.Name
			else
				I = I .. e(H.Name)
			end
			I = I .. "("
			if #H.Arguments > 0 then
				for Q = 1, #H.Arguments do
					I = I .. H.Arguments[Q].Name
					if Q ~= #H.Arguments then
						I = I .. ", "
					elseif H.VarArg then
						I = I .. ", ..."
					end
				end
			elseif H.VarArg then
				I = I .. "..."
			end
			I = I .. ")" .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "GenericForStatement" then
			I = ("\t"):rep(l) .. "for "
			for R = 1, #H.VariableList do
				I = I .. H.VariableList[R].Name
				if R ~= #H.VariableList then
					I = I .. ", "
				end
			end
			I = I .. " in "
			for S = 1, #H.Generators do
				I = f(I, e(H.Generators[S]))
				if S ~= #H.Generators then
					I = f(I, ", ")
				end
			end
			I = f(I, " do") .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "NumericForStatement" then
			I = ("\t"):rep(l) .. "for "
			I = I .. H.Variable.Name .. " = "
			I = I .. e(H.Start) .. ", " .. e(H.End)
			if H.Step then
				I = I .. ", " .. e(H.Step)
			end
			I = f(I, " do") .. i
			l = l + 1
			I = f(I, j(H.Body))
			l = l - 1
			I = f(I, ("\t"):rep(l) .. "end")
		elseif H.AstType == "LabelStatement" then
			I = ("\t"):rep(l) .. "::" .. H.Label .. "::" .. i
		elseif H.AstType == "GotoStatement" then
			I = ("\t"):rep(l) .. "goto " .. H.Label .. i
		elseif H.AstType == "Comment" then
			if H.CommentType == "Shebang" then
				I = ("\t"):rep(l) .. H.Data
			elseif H.CommentType == "Comment" then
				I = ("\t"):rep(l) .. H.Data
			elseif H.CommentType == "LongComment" then
				I = ("\t"):rep(l) .. H.Data
			end
		elseif H.AstType ~= "Eof" then
			print("Unknown AST Type: ", H.AstType)
		end
		return I
	end
	function j(T)
		local U = ""
		h(T)
		for V, W in pairs(T.Body) do
			U = f(U, k(W) .. i)
		end
		return U
	end
	h(a)
	return (j(a):match("^%s*(.-)%s*$"):gsub(",%.%.%.", ", ..."):gsub(", \n", ",\n"))
end
local function decrypt(ret)
	return (ret:gsub("\"[\\%d+]+\"", function(a)
		return "\"" .. loadstring("return " .. a)():gsub(".", function(x)
			return Legends[x] or x
		end) .. "\""
	end))
end
local function _beautify(scr, encrypt, renamevars)
	local st, ast = ParseLua(scr)
	if not st then
		print(ast)
		return scr
	end
	local ret = Format(ast, not not renamevars, false, encrypt)
	if not encrypt then
		ret = decrypt(ret)
	end
	return ret
end
local function _minify(scr, encrypt)
	local st, ast = ParseLua(scr)
	if not st then
		print(ast)
		return scr
	end
	local ret = Format(ast, true, true, encrypt)
	for _ = 1, 2 do
		ret = ret:gsub("%s+", " "):gsub("([%w_]) (%p)", function(a, b)
			if b ~= "_" then
				return a .. b
			end
		end):gsub("(%p) (%p)", function(a, b)
			if a ~= "_" and b ~= "_" then
				return a .. b
			end
		end):gsub("(%p) ([%w_])", function(a, b)
			if a ~= "_" then
				return a .. b
			end
		end)
	end
	if not encrypt then
		ret = decrypt(ret)
	end
	return ret
end
return {
	beautify = _beautify,
	minify = _minify
}
