-- FlashAir W-04 + DRV8830
MD_ADDR = 0x64
-- SPEED
-- 0x3F 0011 1111
-- 0x2F 0010 1111
-- 0x1F 0001 1111
-- 0x0F 0000 1111
STATE_SPEED = 0
STATE_TR = 1

function write_i2c_command(addr, data1, data2)
	res = fa.i2c{ mode="start", address=addr, direction="write" }
	res = fa.i2c{ mode="write", data=data1 }
	res = fa.i2c{ mode="write", data=data2 }
	res = fa.i2c{ mode="stop"}
end

function sendMotorDrive(addr, reg, vset, data)
	local vdata = bit32.bor(bit32.lshift(vset, 2), data)
	write_i2c_command(addr, reg, vdata)
end

function controlSpeed(speednum, tr)
	local tr_reg = 0x00
	if(speednum < 0) then return end
	if(speednum > 200) then return end
	if (tr == 1) then
		tr_reg = 0x01
	else
		tr_reg = 0x02
	end
	if(speednum == 0) then
		sendMotorDrive(MD_ADDR, 0x00, 0x00, 0x03)
    else
	    sendMotorDrive(MD_ADDR, 0x00, (speednum/10)*3+3, tr_reg)
	end
end

function getSharedMem()
  local b = fa.sharedmemory("read", 0, 4)
  if (b == nil) then
    return 0
  else
    STATE_SPEED = tonumber(string.sub(b, 1, 3))
    STATE_TR  = tonumber(string.sub(b, 4, 4))
  end
  return 1
end

function initSharedMem()
  local c = fa.sharedmemory("write", 0, 4, "0000")
  if (c ~= 1) then
    return 0
  end
  return 1
end

res = fa.i2c{ mode="init", freq="100" }
sendMotorDrive(MD_ADDR, 0x00, 0x00, 0x00)

local r = initSharedMem()
if(r ~= 1) then
  return
end
sleep(1000)
while(1) do
  local tmp_spd = STATE_SPEED
  local tmp_tr = STATE_TR
  r = getSharedMem()
  if(r == 1) then
    if(tmp_spd ~= STATE_SPEED or tmp_tr ~= STATE_TR) then
      controlSpeed(STATE_SPEED, STATE_TR)
    end
  end
  sleep(100)
  collectgarbage("collect")
end


