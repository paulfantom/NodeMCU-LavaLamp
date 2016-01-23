collectgarbage()
wifi.sta.autoconnect(1)
lamp = 4
thermometer = 3
-- 105 deg C
critical = 105000

mqtt_host = "192.168.10.3"
mqtt_pass = nil
mqtt_user = nil

state = 0
temp = 85

function lampON()
    if temp < critical then
        print("lamp ON")
        gpio.write(lamp,gpio.HIGH)
        state = 1
    else
        print("Temperature too high")
    end
end

function lampOFF()
    print("lamp OFF")
    gpio.write(lamp,gpio.LOW)
    state = 0
end

function toggle(payload)
    print("change lamp state")
    if gpio.read(lamp) == gpio.HIGH then
        lampOFF()
        return('0')
    else
        lampON()
        return('1')
    end
end

function gettemp()
    t=require("ds18b20")
    t.setup(thermometer)
    temp=t.read()
    if temp == nil then
        temp = 0
    end
    print(temp)
    if temp > critical then
        print("Critical temperature reached, switching lamp off")
        lampOFF()
    end
    t=nil
    ds18b20 = nil
    package.loaded["ds18b20"]=nil
end

tmr.alarm(4,60000,1,function()
    local s = wifi.sta.status()
    if (s < 5) then
        node.restart()
    end
end)

gpio.mode(lamp,gpio.OUTPUT)
lampOFF()
--gettemp()
--tmr.alarm(3,30000,1,gettemp)

print('connecting to MQTT')
--m = mqtt.Client("LavaLamp_"..node.chipid(), 120, mqtt_pass, mqtt_user)
m = mqtt.Client("Lava_"..node.chipid(), 120)
m:connect(mqtt_host, 1883, 0, function()
    print("connected")
    m:subscribe("/lavalamp/change",0)

    tmr.alarm(5, 120000, 1, function()
        gettemp()
        m:publish("/lavalamp/temperature", string.gsub(tostring(temp),"%d%d%d$",".%1"), 0, 1)
    end)
end)

m:on("message", function(conn, topic, data)
    if (data == "on" ) then
        lampON()
    end
    if (data == "off" ) then
        lampOFF()
    end
    if (data == "toggle" ) then
        toggle()
    end
    if (data ~= nil ) then
        print(topic .. ":" .. data )
        m:publish("/lavalamp", "{state:"..tostring(state).."temperature:"..tostring(temp).."}", 0, 1)
    end
end)