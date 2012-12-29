#!/usr/bin/lua

require "luarocks.loader"

local http = require("socket.http")
local ltn12 = require("ltn12")

local manga = {}

function manga.prepare()
	 -- install luarocks
	 os.execute('sudo apt-get install luarocks imagemagick')

	 -- install luasocket
	 os.execute('luarocks --local install LuaSocket')
end

function manga.load( name )
	 local res = require(name)
	 
	 assert( res )
	 return res
end

local function shell( cmd )
   -- to execute and capture the output, use io.popen
   local f = io.popen( cmd ) -- store the output in a "file"
   local res =  f:read("*a")    -- print out the "file"'s content
   f:close()
	 
   -- chomp result
   return string.gsub(res, "[\r\n]+$", "")
end


local function kobo( file )
	 -- should we rotate ?
	 local h = shell('identify -format "%[fx:h]" '..file):match('%d+')
	 local w = shell('identify -format "%[fx:w]" '..file):match('%d+')
	 
	 w = tonumber(w)
	 h = tonumber(h)
	 
	 local cmd = 'convert -size 600x800 '

	 local rotate = w > h
	 if rotate then 
			cmd = cmd .. '-rotate -90 '
	 end

	 os.execute( cmd ..' '.. file ..' ' .. file )
end

local function get(url, out)
	 local res = true
	 
	 io.write( 'requesting ' .. url )
	 local b, c, h = http.request{
			url = url,
			sink = ltn12.sink.file( io.open(out, 'w') )
	 }

	 if not h then 
			print( "error accessing", url )
	 end
	 
	 -- bogus status
	 if h.location or c == 300 or c == 404 then 
			res = false
			print('', 'derp!')
	 else
			print('', math.floor(h['content-length'] / 1024) .. 'kB')
	 end
	 
	 -- cleanup
	 if not res then 
			os.execute('rm ' .. out)
	 else 
			kobo( out )
	 end
	 
	 return res
end



function manga.fetch( name, issue ) 
	 local dir = name .. '/' .. issue

	 local err = os.execute('mkdir -p ' .. dir )
	 
	 local conf = manga.load( name )

	 local s, e = conf.pages( issue )
	 for p = s, e do
			local url = conf.url(issue, p)
			local out = dir .. '/' .. conf.basename(p)
			
			if not get(url, out) then
				 
				 -- let's try alternate url instead
				 url = conf.url(issue, p, true)
				 out = dir .. '/' .. conf.basename(p, true)
				 
				 if get( url, out ) then
						-- great success
						
				 else
						-- warning: premature exit
						print('warning: page ' .. p ..' not found' )
				 end
			end
	 end
end



function manga.assemble(name, issue )

	 local cbz =  name .. '/' .. name .. '-' .. issue ..'.cbz'
	 local list = name .. '/' .. issue .. '/*'

	 os.execute('rm ' .. cbz)
	 os.execute('zip -9 ' .. cbz .. ' ' .. list)

	 print( 'assembled ' .. cbz )
end




local function fix( id, n )
	 
	 -- local diff = math.pow(10, n) - id
	 
	 -- if diff > 0 then
	 -- 		return string.rep( '0', tostring(diff):len())..tostring(id)
	 -- else
	 -- 		return tostring(id)
	 -- end

	 local fmt = '%0'..n..'d'
	 return string.format(fmt, id)
end


-- we use links so that filenames remain ordered
function manga.assemble_all(name) 
	 local cbz =  name .. '.cbz'

	 local issues = shell( 'ls -1 ' .. name )

	 local tmp_dir = '/tmp/'..name
	 local curr_dir = os.getenv("PWD")

	 local n = shell( 'ls -1 ' .. name .. ' | wc -l' ):len()
	 
	 print('creating links...')
	 os.execute('mkdir ' .. tmp_dir)
	 for i in string.gmatch( issues, '[^%s]+' ) do
			
			if tonumber(i) then 
				 local files = shell( 'ls -1 ' .. name .. '/' .. i )
				 
				 for f in string.gmatch( files, '[^%s]+' ) do
						
						local filename = curr_dir .. '/' .. name .. '/' .. i .. '/' .. f
						local link = tmp_dir .. '/' .. fix( tonumber(i), n) .. '-' .. f
						
						-- print( filename )
						os.execute('ln -sv ' .. filename .. ' ' .. link )
				 end
			end
	 end
	 
	 os.execute('zip -9 ' .. cbz .. ' ' .. tmp_dir .. '/*')
	 os.execute('rm -rf ' .. tmp_dir )
	 
	 print( 'assembled ' .. cbz )
end


function manga.fetch_all(name)
	 local conf = manga.load(name)

	 local s, e = conf.issues()

	 for i = s, e do
			manga.fetch(name, i)
	 end
end





local function wrap_arg(fun_name) 
	 return function(context, i, arg) 
						 local name = context.name
						 local id = tonumber( arg[ i + 1 ] )
						 assert( id )
						 return function() manga[fun_name](name, id ) end
					end
end

local function wrap_noarg(fun_name) 
	 return function(context, i, arg) 
						 local name = context.name
						 return function() manga[fun_name](name) end
					end
end





local cmd = {

	 ['--fetch'] = wrap_arg('fetch'),
	 ['--assemble'] = wrap_arg('assemble'),
	 ['--fetch_all'] = wrap_noarg('fetch_all'),
	 ['--assemble_all'] = wrap_noarg('assemble_all'),
	 
	 ['--name'] = function(context, i , arg)
									 context.name = arg[i + 1]
								end,
	 
	 ['--prepare'] = function(context, i, arg) 
											manga.prepare()
									 end,
}


-- local options = {
	 
	 
-- 	 ['--fetch'] = function(res, i, arg) 
-- 									assert( arg[i + 1] )
-- 									res.fetch = {res.name, arg[i + 1]}
-- 							 end,
	 
-- 	 ['--fetch_all'] = function( res, i, arg) 
-- 												res.fetch_all = { res.name }
-- 										 end,
	 
-- 	 ['--assemble'] = function(res, i, arg) 
-- 											 assert( arg[i + 1] )
-- 											 res.assemble = { res.name, arg[i + 1]}
-- 										end,
-- }


local function parse( arg )

	 local context = {}
	 local res = {}
	 
	 for i,v in ipairs(arg) do
			if cmd[v] then
				 local todo = cmd[v](context, i, arg)
				 if todo then table.insert(res, todo) end
			end
	 end
	 
	 return res
end


local todo_list = parse( arg )

for i,act in ipairs(todo_list) do
	 act()
end

return manga