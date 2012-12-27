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


require "luarocks.loader"

local http = require("socket.http")
local ltn12 = require("ltn12")
require("LuaXml")

function res.issues()
	 return 1, 111
end


local website = 'http://www.mangareader.net'

local function fetch()
	 print('fetching data...')
	 
	 local home = website .. '/1047/battle-angel-alita-last-order.html'

	 local t = {}
	 
	 local b, c, h = http.request{
			url = home,
			sink = ltn12.sink.table( t )
	 }
	 
	 local data = table.concat( t ) 

	 local res = {}

	 local patterns = { 
			'(/[%d-]+/battle.angel.alita.last.order/chapter.(%d+).html)', -- up to 100
			'(/battle.angel.alita.last.order/(%d+))'											 -- after 100
	 }
	 
	 for _,p in ipairs( patterns ) do 
			
			for rel_url, chap in data:gmatch(p) do
				 local id = tonumber(chap)

				 if not res[id] then 
						res[id] = {}
						
						local url = website..rel_url
						
						print('parsing', url )
						
						res[id].url = url

						t = {}

						b, c, h = http.request{
							 url = url,
							 sink = ltn12.sink.table( t )
						}
						
						local data = table.concat( t )

						local doc = xml.eval(data)
						
						local pages = data:match( '</select>%s+of%s+(%d+)' )
						
						local img = doc:find('img', 'id', 'img')

						res[id].pages = tonumber(pages)
						res[id].start = img.src
				 end
			end
	 end
	 print( 'done.')
	 
	 return res
end




local function serialize( file, data )
	 if type(data) == "table" then
			file:write('{')
			
			for k,v in pairs(data) do
				 file:write('[')
				 serialize(file, k)
				 file:write('] = ')
				 serialize(file, v)
				 file:write(', ')
			end
			
			file:write('}')
	 elseif type(data) == 'string' then
			file:write("'")
			file:write( data )
			file:write("'")
	 elseif type(data) == "number" then
			file:write( tostring(data) )
	 end

end

local function write(filename, data)
	 local f = assert( io.open(filename, 'w') )

	 f:write( 'return ' )
	 serialize( f, data )
	 f:close()
	 
end

local data_filename = "gunnm-last-order/data.lua"


local function load() 
	
	 local f = loadfile( data_filename )
	 if f then 
			return f() 
	 else
			local data = fetch()
			write( data_filename, data )
			return data
	 end
end

local data = load()


function res.pages( issue )
	 return 1, data[issue].pages
end





function res.url(issue, page, double)
	 local url = data[issue].start

	 local base = url:match('(%d+)\.jpg') 
	 
	 local delta = page - 1

	 if issue > 100 then delta = 2 * delta end

	 local new = tonumber(base) + delta
	 
	 local res = url:gsub(base, tostring(new))
	 
	 return res
end


return res
