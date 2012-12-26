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

local start = 980216

local pages = {
	 [1] = 45,
	 [2] = 32,
	 [3] = 32, 
	 [4] = 32,
	 [5] = 25,
	 [6] = 31,
	 [7] = 36,
	 [8] = 31,
	 [9] = 32,
	 [10] = 28,
	 [11] = 30,
	 [12] = 38,
	 [13] = 28,
	 [14] = 32,
	 [15] = 31,
	 [16] = 32,
	 [17] = 32,
	 [18] = 33,
	 [19] = 36,
	 [20] = 22,
}

-- TODO cache this
local function offset( issue ) 
	 local res = 0

	 for i = 1, issue - 1 do
			res = res + pages[i]
	 end
	 
	 return res
end

local function filenumber(issue, page)
	 return start + offset(issue) + page
end

function res.url(issue, page, double)
	 -- http://i27.mangareader.net/battle-angel-alita-last-order/1/battle-angel-alita-last-order-980217.jpg

	 local glo = 'battle-angel-alita-last-order'

	 local res = 'http://i27.mangareader.net/'

	 res = res .. glo .. '/' .. issue .. '/' .. glo ..'-' .. filenumber(issue, page) .. '.jpg'

	 return res
end

function res.issues()
	 return 1, 7
end



function res.pages( issue )
	 return 1, pages[issue]
end


	 


return res
