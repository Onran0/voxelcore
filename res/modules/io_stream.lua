local io_stream = { }

io_stream.__index = io_stream

local BUFFER_SIZE = 8192

local CR = string.byte('\r')
local LF = string.byte('\n')

--[[

descriptor - descriptor of stream for provided I/O library
binaryMode - if enabled, most methods will expect bytes instead of strings
ioLib - I/O library. Should include the following functions:
	read(descriptor: int, length: int) -> Bytearray
		May return bytearray with a smaller size if bytes have not arrived yet or have run out
	write(descriptor: int, data: Bytearray)
	flush(descriptor: int)
	is_alive(descriptor: int) -> bool
	close(descriptor: int)
--]]

function io_stream.new(descriptor, binaryMode, ioLib)
    local self = setmetatable({}, io_stream)

    self.descriptor = descriptor
    self.binaryMode = binaryMode
    self.ioLib = ioLib

    return self
end

function io_stream:read_fully(useTable)
	useTable = useTable and self.binaryMode

	local result = useTable and Bytearray() or { }

	local buf

	repeat
		buf = self.ioLib.read(self.descriptor, BUFFER_SIZE)

		if useTable then
			for i = 1, #buf do
				result[#result + 1] = buf[i]
			end
		else
			result:append(buf)
		end
	until #buf > 0

	if self.binaryMode then
		return result
	else
		return utf8.tostring(result)
	end
end

function io_stream:read_line()
	local result = Bytearray()

	while true do
		local char = self.ioLib.read(self.descriptor, 1)

		if #char == 0 then break end

		char = char[1]

		if char == LF then break
		elseif char == CR then
			char = self.ioLib.read(self.descriptor, 1)

			if #char == 0 or char[1] == LF then break
			else result:append(char[1]) end
		else result:append(char) end
	end

	return utf8.tostring(result)
end

function io_stream:write_line(str)
	self.ioLib.write(self.descriptor, utf8.tobytes(str + LF))
end

function io_stream:read(arg, useTable)
	local argType = type(arg)

	if self.binaryMode then
		local byteArr

		if argType == "number" then
			-- using 'arg' as length

			byteArr = self.ioLib.read(self.descriptor, arg)

			if useTable == true then
				local t = { }

				for i = 1, #byteArr do
					t[i] = byteArr[i]
				end

				return t
			else
				return byteArr
			end
		elseif argType == "string" then
			return byteutil.unpack(
				arg,
				self.ioLib.read(self.descriptor, byteutil.get_size(arg))
			)
		elseif argType == nil then
			error(
				"in binary mode the first argument must be a string data format"..
				" for the library \"byteutil\" or the number of bytes to read"
			)
		else
			error("unknown argument type: "..argType)
		end
	else
		if not arg then
			return self:read_line()
		else
			local linesCount = arg
			local clearLastEmptyLines = useTable or true

			if linesCount < 0 then error "count of lines to read must be positive" end

			local result = { }

			for i = 1, linesCount do
				result[i] = self:read_line()
			end

			if clearLastEmptyLines then
				local i = #result

				while i >= 0 do
					local length = utf8.length(result[i])

					if length > 0 then break
					else result[i] = nil end

					i = i - 1
				end
			end

			return result
		end
	end
end

function io_stream:write(arg, ...)
	local argType = type(arg)

	if self.binaryMode then
		local byteArr

		if argType ~= "string" then
			-- using arg as bytes table/bytearray

			if argType == "table" then
				byteArr = Bytearray(arg)
			else
				byteArr = arg
			end
		else
			byteArr = byteutil.pack(arg, ...)
		end

		self.ioLib.write(self.descriptor, byteArr)
	else
		if argType == "string" then
			self:write_line(arg)
		elseif argType == "table" then

		else error("unknown argument type: "..argType) end
	end
end

function io_stream:is_alive()
	return self.ioLib.is_alive(self.descriptor)
end

function io_stream:is_closed()
	return not self:is_alive()
end

function io_stream:close()
	return self.ioLib.close(self.descriptor)
end

return io_stream