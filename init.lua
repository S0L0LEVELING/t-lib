if (IsDuplicityVersion()) then -- Run on server
    lib = {}
else -- Run on client
    lib = {await={}}
end