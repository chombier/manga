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

function res.url(issue, page, double)
	 return 'http://opluffy.com/lecture/lec/' .. issue .. '/' .. res.basename(page, double)
end

function res.issues()
	 return 637, 693
end

function res.pages( issue )
	 return 1, 20
end

return res

