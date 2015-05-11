collectgarbage()
wifi.sta.autoconnect(1)
lamp = 4
thermometer = 3
refresh_rate = 30000
critical = 120

function lampON()
    if temp < critical then
        gpio.write(lamp,gpio.HIGH)
        state = 1
    else
        print("Temperature too high")
    end
end

function lampOFF()
    gpio.write(lamp,gpio.LOW)
    state = 0
end

function gettemp()
    t=require("ds18b20")
    t.setup(thermometer)
    temp=t.read(nil,t.C)
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

function toggle(payload)
    --TODO broadcast via CoAP
    print("change lamp state")
    if gpio.read(lamp) == gpio.HIGH then
        lampOFF()
        return('0')
    else
        lampON()
        return('1')
    end
end

state = 0
temp = 0.0

gpio.mode(lamp,gpio.OUTPUT)
lampOFF()
gettemp()
tmr.alarm(0,refresh_rate,1,gettemp)
refresh_rate = nil

print('starting CoAP server')
cs = coap.Server()
cs:listen(5683)

cs:func("toggle")
--TODO observable resource 'state'
cs:var("state")
--TODO observable resource 'temp'
cs:var("temp")
cs:var("critical")

print('starting HTTP server')
srv=net.createServer(net.TCP,30)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end
        buf = buf.."<h1> Lava Lamp</h1>";
        buf = buf.."<p>Turn light <a href=\"?pin=ON\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF\"><button>OFF</button></a></p>";
        buf = buf.."<p>Temperature: "..string.format("%2.2f", temp).." C</p>";
        local _on,_off = "",""
        if(_GET.pin == "ON")then
              lampON();
        elseif(_GET.pin == "OFF")then
              lampOFF();
        end
        client:send(buf);
        client:close();
        collectgarbage();
    end)
end)
