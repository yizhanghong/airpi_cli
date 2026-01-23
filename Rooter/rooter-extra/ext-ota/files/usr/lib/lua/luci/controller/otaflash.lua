module("luci.controller.otaflash", package.seeall)

I18N = require "luci.i18n"
translate = I18N.translate

function index()
	entry({"admin", "system", "otaflash"}, template("flash/flash"), translate("Over-the-Air Update"), 71)
	
	entry({"admin", "adminmenu", "settime"}, call("action_settime"))
	entry({"admin", "adminmenu", "getflash"}, call("action_getflash"))
	entry({"admin", "adminmenu", "setenable"}, call("action_setenable"))
	entry({"admin", "adminmenu", "check"}, call("action_check"))
	entry({"admin", "adminmenu", "manual"}, call("action_manual"))
end

function action_settime()
	local set = luci.http.formvalue("set")
	
	os.execute("/usr/lib/flash/settime.sh " .. set)
end

function action_setenable()
	local set = luci.http.formvalue("set")
	
	os.execute("/usr/lib/flash/setenable.sh " .. set)
end

function action_getflash()
	local rv = {}
	
	rv['time'] = luci.model.uci.cursor():get("flash", "flash", "time")
	rv['enabled'] = luci.model.uci.cursor():get("flash", "flash", "enabled")
	rv['last'] = luci.model.uci.cursor():get("flash", "flash", "last")
	rv['lastdate'] = luci.model.uci.cursor():get("flash", "flash", "date")
	if rv['lastdate'] == nil then
		rv['lastdate'] = "---"
	end
	if rv['last'] == nil then
		rv['last'] = "---"
	end
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_check()
	local rv = {}
	os.execute("/usr/lib/flash/check.sh ")
	file = io.open("/tmp/checkfirm", "r")
	rv['check'] = file:read("*line")
	file:close()
	rv['lastchk'] = luci.model.uci.cursor():get("flash", "flash", "lastchk")
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_manual()
	local rv = {}
	os.execute("/usr/lib/flash/manual.sh ")
	file = io.open("/tmp/checkfirm", "r")
	rv['check'] = file:read("*line")
	file:close()
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end