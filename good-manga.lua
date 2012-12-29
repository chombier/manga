require "luarocks.loader"
local http = require("socket.http")
local ltn12 = require("ltn12")
require("LuaXml")

local res = {}

local function get( url )
	 
	 local t = {}
	 
	 local b, c, h = http.request{
			url = url,
			sink = ltn12.sink.table( t )
	 }
	 
	 local data = table.concat( t ) 
	 -- print( data )
	 
	 return xml.eval( data )
end


local function find(doc, str)
	 
	 for i,x in ipairs(doc) do
			-- print(i, x)
			if type(x) == "table" then
				 local sub = find( x, str )
				 if sub then return sub end;
			elseif type(x) == "string" then
				 if x == str then 
						return doc
				 end
			end
	 end
	 
	 return nil
end


function res.main( name )
	 
	 local doc = get('http://www.goodmanga.net/manga-list')

	 local node = find( doc, 'One Piece' )

	 return node.href
end


function res.issues(name)
	 
	 local url = res.main( name )

	 local doc = get( url )

	 local div = doc:find('div', 'id', 'chapters' )
	 
	 local last_url = div:find('a').href
	 
	 return tonumber( last_url:match('/(%d+)$') )
end


local function convert( name )
	 return name:lower():gsub(' ', '_')
end


function res.pages(name, issue)

	 local url = 'http://www.goodmanga.net/' .. convert(name) .. '/chapter/' .. issue

	 local doc = get( url )

	 local div = doc:find('div', 'id', 'manga_nav_top')
	 
	 local span = div:find('span')[3]

	 local count = span[1]:match('of%s+(%d+)')

	 return tonumber(count)
end


function res.url(name, issue, page)
	 return 'http://r1.goodmanga.net/images/manga/' .. convert(name) .. '/'.. issue .. '/' .. page .. '.jpg'
end


function res.new(name) 
	 local r = {}

	 function r.pages( issue ) 
			return res.pages(name, issue)
	 end
	 
	 function r.issues( ) 
			return 1, res.issues(name)
	 end

	 function r.pages( chap ) 
			return 1, res.pages(name, chap)
	 end

	 function r.url(issue, page) 
			return res.url(name, issue, page)
	 end

	 function r.basename(page)
			local fmt = '%03d'
			return string.format(fmt, page) .. '.jpg'
	 end
	 
	 return r
end


return res