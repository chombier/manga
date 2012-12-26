local res = {}


local function fix( id )
	 if id < 10 then id = '0' .. id end

	 return tostring( id )
end

function res.basename(page, double)
	 local filename = fix( page )
	 if double then filename = filename .. '-' .. fix(page + 1) end

	 filename = filename .. '.jpg'

	 return filename
end

function res.url(issue, page, alt)
	 if alt then page = fix(page) end
	 return 'http://lelscan.com/mangas/fairy-tail/' .. issue .. '/' .. page .. '.jpg?v=f'
end

function res.issues()
	 return 291, 312
end

function res.pages( issue )
	 return 2, 25
end

return res

