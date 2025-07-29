return function(path)
	if path:find("/../") or path:find("\\..\\") or path:starts_with("../") or path:starts_with("..\\") then
		error "special path \"../\" is not allowed in path to named pipe"
	end
end