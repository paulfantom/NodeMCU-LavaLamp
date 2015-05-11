gpio.mode(4,gpio.OUTPUT)
gpio.write(4,gpio.LOW)
gpio.mode(3,gpio.OUTPUT)
gpio.write(3,gpio.LOW)

if file.open('wifi.cfg','r') then
    local i = 0
    file.close()
    if file.open('reconf','r') then
        file.close()
        file.remove('wifi.cfg')
        file.remove('reconf')
        dofile('ap.lc')
    else
        file.close()
        file.open('reconf','w+')
        file.write('')
        file.flush()
        file.close()
        repeat
            if i % 2 == 0 then
                gpio.write(3,gpio.HIGH)
                gpio.write(4,gpio.HIGH)
            else
                gpio.write(3,gpio.LOW)
                gpio.write(4,gpio.LOW)
            end
            tmr.delay(2000000)
            i = i + 1
        until i > 6       
    end 

    file.remove('reconf')
    file.open("wifi.cfg","r")
    wifi.setmode(wifi.STATION)
    --SSID = file.readline()
    local SSID = string.sub(file.readline(),0,-2)
    --APPWD = file.readline()
    local APPWD = string.sub(file.readline(),0,-2)
    file.close()
    print("SSID: '"..SSID.."'")
    print("APPWD: '"..APPWD.."'")
    wifi.sta.getip()
    wifi.sta.config(SSID,APPWD)
    wifi.sta.autoconnect(1)
    i=0
    tmr.alarm (1, 500, 1, function ()
        if wifi.sta.getip () ~= nil then
            tmr.stop(1)
            --print("Connected to AP, IP is " .. wifi.sta.getip())
            dofile("lavalamp.lc")
        end
        -- 5 minutes
        if i > 600 then
            tmr.stop(1)
            file.remove("wifi.cfg")
            node.restart()
            print("Cannot connect to AP : "..wifi.sta.status())
        end
        print(i)
        i = i + 1
    end)
else
    dofile("ap.lc")
end