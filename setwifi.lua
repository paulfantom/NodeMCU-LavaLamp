--setwifi.lua

print("Entering wifi Setup..")

wifi.setmode(wifi.STATIONAP)
cfg={}
    cfg.ssid="Lava Lamp"
    --cfg.password="12345678" --comment to leave open
wifi.ap.config(cfg)

ipcfg={}
    ipcfg.ip="192.168.1.1"
    ipcfg.netmask="255.255.255.0"
    ipcfg.gateway="192.168.1.1"
wifi.ap.setip(ipcfg)

ap_list = ""

function listap(t)
  for bssid,v in pairs(t) do
   local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
    ap_list = ap_list.."<option value='"..ssid.."'>"..ssid.."</option>"
  end
end
wifi.sta.getap(1, listap)

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            --for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
            for k, v in string.gfind(vars, "([^&=]+)=([^&=]+)") do
                _GET[k] = v
            end
        end

        if path == "/favicon.ico" then
            conn:send("HTTP/1.1 404 file not found")
            return
        end   

        if (path == "/" and  vars == nil) then
            buf = buf.."<html><body style='width:90%;margin-left:auto;margin-right:auto;background-color:LightGray;'>";
            buf = buf.."<h1>LavaLamp Wifi Configuration</h1>"
            buf = buf.."<form action='' method='get'>"
            buf = buf.."<h4>SSID:</h4>"
            buf = buf.."<input type='text' name='ssid' value='' maxlength='100' width='100px' placeholder='ssid' />"
            buf = buf.."<br>"
            buf = buf.."<h4>Password:</h4>"
            buf = buf.."<input type='text' name='password' value='' maxlength='100' width='100px' placeholder='empty if AP is open' />"
            buf = buf.."<br>"
            buf = buf.."<h4>MQTT broker address/hostname:</h4>"
            buf = buf.."<input type='text' name='mqtt_host' value='' maxlength='100' width='100px' placeholder='MQTT broker'/>"
            buf = buf.."<br>"
            buf = buf.."<p><input type='submit' value='Submit' style='height: 25px; width: 100px;'/></p>"
            buf = buf.."</body></html>"

        elseif (vars ~= nil) then
            restarting = "<html><body style='width:90%;margin-left:auto;margin-right:auto;background-color:LightGray;'><h1>Restarting...You may close this window.</h1></body></html>"
            client:send(restarting);
            client:close();
            ssid = "";
            password = "";
            if(_GET.dssid) then
                ssid = _GET.dssid
            end
            if (_GET.ssid) then
                ssid = _GET.ssid
                ssid = string.gsub(ssid,"+"," ")
            end
            if (_GET.password) then
                password = _GET.password
            end
            -- TODO save mqtt_* variables to EEPROM?
            if (_GET.mqtt_host) then
                mqtt_host = _GET.mqtt_host
            end
--            if (_GET.mqtt_user) then
--                mqtt_user = _GET.mqtt_user
--            end
--            if (_GET.mqtt_pass) then
--                mqtt_pass = _GET.mqtt_pass
--            end
            print("Setting to: "..ssid..":"..password)
            tmr.alarm(0, 5000, 1, function()
                wifi.setmode(wifi.STATION);
                wifi.sta.config(ssid,password);
                node.restart();
            end)
        end

        client:send(buf);
        client:close();
        collectgarbage();
    end)
    
end)
