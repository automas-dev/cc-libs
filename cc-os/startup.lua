print('Loading os')

for k, v in pairs(_ENV) do
    print('env', k, v)
end

os.run(_ENV, 'sys/boot.lua')
