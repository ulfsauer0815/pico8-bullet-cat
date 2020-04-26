pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- Bullet Cat
-- by Ulf Sauer


local PS_LEFT=         {i=3,x=24,y=0}
local PS_LEFT_MV=      {i=5,x=40,y=0}
local PS_RIGHT=        {i=4,x=32,y=0}
local PS_RIGHT_MV=     {i=6,x=48,y=0}
local PS_UP=           {i=1,x=8,y=0}
local PS_DOWN=         {i=2,x=16,y=0}

local SND_JUMP=0

local debug=true
local draw_bounds=false
local update=true
local message=''
local draw_map=true
local draw_enemies=true
local dead_time=0

local out
local player
local enemy1
local enemy2
local objects
local enemies


local Object={}

function Object:new(x,y)
	o = {}
	setmetatable(o, self)
	self.__index = self
  return o
end

local Player=Object:new()
local Enemy=Object:new()

-- global

function _init()
	player=Player:new(63,31)
	enemy1=Enemy:new(10,49)
	enemy2=Enemy:new(80,49)
	objects={player, enemy1, enemy2}
	enemies={enemy1, enemy2}

	foreach(objects, function(o) if o.init then o:init() end end)
end


local FRAME_RATE=60
local FRAME_FACTOR=30/FRAME_RATE
function _update60()
	if btnp(5) then
		draw_bounds=not draw_bounds
	end

	if not player:is_alive() then
		dead_time+=1/FRAME_RATE
	end

	if not update then
		return
	end
	foreach(objects, function(o) if o.update then o:update() end end)
	for enemy in all(enemies) do
		if player:intersects(enemy) then
			player:hit()
		end
	end
	if player:is_invincible() then
		message='get ready'
	else
		message=''
	end
end


function _draw()
	cls()

	-- debug
	if debug then
		if out then
			print(out)
		end
	end

	-- map
	if draw_map then
		map(0,0,0,0,16,16)
	end

	-- objects
	foreach(objects, function(o) if o.draw then o:draw() end end)

	-- ui
	draw_hearts(player.lives)
	if message then
		print(message, 128/2-#message/2*4,40, 1)
	end
end


function draw_hearts(n)
	for y=0,(n-1)*8,8 do
		spr(48,y,25)
	end
end

-- Object

function Object:get_bounds()
	local y_off=self.bounds_y_offset or 0
	local x_off=self.bounds_x_offset or 0
	return {
		xs=self.x+(8-self.width)/2 + x_off,
		xe=self.x+self.width+(8-self.width)/2-1 + x_off,
		ys=self.y + y_off,
		ye=self.y+self.height-1 + y_off,
	}
end


function Object:on_ground()
	return self.y >= 56
end


function Object:is_moving()
	return self.vx != 0 or self.vy != 0
end

-- Player

function Player:new(x, y)
	o = {
		x=x,
		y=y,
		width=4,
		height=8,
		sprite=PS_UP,
		jump_energy=1.5,
		move_energy=0.4,
		vy=0,
		vx=0,
		accel_max=2,
		gravity=0.1,

		lives=1,
		hit_timer=0,
		invincibility_period=3*30,
	}
	setmetatable(o, self)
	self.__index = self
  return o
end


function Player:hit()
	if not self:is_invincible() then
		self.lives-=1
		if self:is_alive() then
			self.hit_timer=self.invincibility_period
		end
	end
end


function Player:is_alive()
	return self.lives > 0
end


function Player:is_invincible()
	return self.hit_timer>0
end


function Player:intersects(o)
	local bounds=self:get_bounds()
	local o_bounds=o:get_bounds()
	local x_intersects=bounds.xe > o_bounds.xs and bounds.xs <= o_bounds.xe
	local y_intersects=bounds.ye > o_bounds.ys and bounds.ys <= o_bounds.ye

	return x_intersects and y_intersects
end


function Player:controls_update()
	if btn(2) then
		self.sprite=PS_DOWN
	end
	if btn(3) then
		self.sprite=PS_UP
	end
	if btn(0) then
		self.sprite=PS_LEFT_MV
		self.vx=max(-self.accel_max, self.vx-self.move_energy*FRAME_FACTOR)
	elseif btn(1) then
		self.sprite=PS_RIGHT_MV
		self.vx=min(self.accel_max, self.vx+self.move_energy*FRAME_FACTOR)
	else
		if self.vx <= self.move_energy and self.vx >= -self.move_energy then
			self.vx=0
		else
			self.vx=self.vx-sgn(self.vx)*self.move_energy*FRAME_FACTOR
		end
	end
	if btnp(4) and self:on_ground() then
		self.vy=-self.jump_energy
		sfx(SND_JUMP)
	end
end


function Player:init()
	self.hit_timer=self.invincibility_period
end


function Player:update()
	if not self:is_alive() then
		draw_map=false
		draw_enemies=false
		update=false
	end
	self:controls_update()
	self.x+=self.vx*FRAME_FACTOR
	self.y+=self.vy*FRAME_FACTOR
	self.vy=self.vy+self.gravity*FRAME_FACTOR

	if self:on_ground() then
		self.vy=0
		self.y=56
	end

	if self:is_invincible() then
		self.hit_timer-=1*FRAME_FACTOR
	end
	if not self:is_alive() then
		self.sprite=PS_UP
	end

	if not self:is_moving() then
		self.sprite=PS_UP
	end
end


function Player:draw()
	local frequency_correction=2
	local frequency=(self.hit_timer/self.invincibility_period)*5+frequency_correction
	local flicker=self.hit_timer / frequency % 1 < 0.5
	if self:is_invincible() and not flicker then
		pal(9,7)
	end
	local fraction=self.invincibility_period/8
	local visibility=max(0,self.hit_timer-(self.invincibility_period-fraction))/fraction
	local factor_1=min(12, dead_time*14)
	local factor=1+factor_1
	local offset=factor_1*8/2
	local x_distance=63-self.x-8/2
	local y_distance=63-self.y-8/2
	local distance_scale=min(1,factor_1/12)
	local x_distance_inc=x_distance*distance_scale
	local y_distance_inc=y_distance*distance_scale
	sspr(self.sprite.x, self.sprite.y, 8, 8*(1-visibility), self.x-offset+x_distance_inc, self.y-offset+y_distance_inc, 8*factor, 8*factor*(1-visibility))

	pal()
	if draw_bounds then
		local bounds=self:get_bounds()
		rect(bounds.xs, bounds.ys, bounds.xe, bounds.ye, 8)
	end
end


-- Enemy

function Enemy:new(x,y)
	o = {
		is_enemy=true,
		x=x,
		y=y,
		bounds_y_offset=2,
		width=8,
		height=6,
		sprite={i=32,x=0,y=16},
		sprite_flip=true,
		vx=2,
		vy=0,
		gravity=0.2,
	}
	setmetatable(o, self)
	self.__index = self
  return o
end


function Enemy:update()
	if self.x+self.width/2 >= 128 then
		self.vx = self.vx*-1
	end
	if self.x <= 0 then
		self.vx = self.vx*-1
	end

	if self:on_ground() then
		self.vy=0
		self.y=56
	end
	self.x+=self.vx*FRAME_FACTOR
	self.y+=self.vy*FRAME_FACTOR
	self.vy=self.vy+self.gravity*FRAME_FACTOR
	self.sprite_flip=self.vx>=0
end


function Enemy:draw()
	if not draw_enemies then
		return
	end
	spr(self.sprite.i,self.x,self.y,1,1,self.sprite_flip)
	if draw_bounds then
		local bounds=self:get_bounds()
		rect(bounds.xs, bounds.ys, bounds.xe, bounds.ye, 8)
	end
end

__gfx__
00000000005555000055550000555500005555000555500000055550000000000000000000000000000000000000000000000000000000000000000000000000
00000000005555000055550000555500005555000555500000055550000000000000000000000000000000000000000000000000000000000000000000000000
00700700022922200299992000229500005922000229500000059220000000000000000000000000000000000000000000000000000000000000000000000000
00077000009999000099990000999900009999000999900000099990000000000000000000000000000000000000000000000000000000000000000000000000
00077000009999000099990000999900009999000999900000099990000000000000000000000000000000000000000000000000000000000000000000000000
00700700006666000066660000666000000666000066600000066600000000000000000000000000000000000000000000000000000000000000000000000000
00000000006066000066060000606600006606000060660000660600000000000000000000000000000000000000000000000000000000000000000000000000
00000000004004000040040000040400004040000004040000404000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02288670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82e88788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888888e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008ee8e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8e888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88eeee88800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e88ee88ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088888e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e888e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbb5bbbbb44444444444494449444944444449444cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
bbbbbbbbb55bbbbb44444444444494449444944444449444ccccccccccccccc7777c7777777c77777ccccccc0000000000000000000000000000000000000000
bbbbbbbbb5bbbb5b44444444444494445444944444449444ccccccccccccc777777777767777777777cccccc0000000000000000000000000000000000000000
bbbbbbbbb55bbb5b44444444444994444449944444499444ccccccccccccc7777777776c7777777776cccccc0000000000000000000000000000000000000000
bbbbbbbbbbbbb55b44444444444994444449944444499444ccccccccccccc666666666cc677777666ccccccc0000000000000000000000000000000000000000
bbbbbbbbbbbbb5bb44444444449994444445544444999444ccccccccccccccccccccccccc66667cccccccccc0000000000000000000000000000000000000000
bbbbbbbbb55bb5bb44444444499594444444444449959444ccccccccccccccccccccccccccccc6cccccccccc0000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb44444444995494444444444499549444cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbb33bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbb333bbbbb344bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333bb33333b33bb33344433b3b44433b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44433444443443344444444343444443000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb333bbbbbbb33bbbbb333bb33b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333bb344433bb3334433333444334434000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44433444444334444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000004444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000004b45555555bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000044b5544444bb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004444b4444444b34440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000044455b555555bb44444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000455554b444444b355555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000044444443b4444bb444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000444445555bb444b3445544444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004555555eee3bb553555ee55554400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004500eeeeeeeeb3eeeeeeeeeee05400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400ee7777777777eee777777e00540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500ee6666676666eee666766e00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbe6667676666eee667766ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003bbbb66666666eee676666ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000333bb6666666eee676666ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ee63b6666666eee666666ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000eeeebeeebeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000eeebbebbeeeeeeeeeeeeebb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000eee3bbb3eeeeeeeeeeeeeb3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000eeeeeb33eee4455466eeebb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000beeeebbeeeee4544566eeeb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000beebbb3eeeee5544466eee3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbbb33eeeeee4455466eee3bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000033bbeeeeeeee4454466eeee3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000e3beeeeeeee4444466eeeeeb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000eebbeeeeeee4544466eeeee3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ee3beeeeeee4546666eeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000eebeeeeeee4466666eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000055550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000055550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000229222000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000066660000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000060660000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000040040000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4646464646464646464646464646464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4746474949494a46464646464646464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
464646464646464646464647494a464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4646464646464646464646464646464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4646464646464646464646464646464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040414040404040414040414040404100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6362625060606252635253625062525100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242424242444242424242424242424200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242454242424242424242424242454200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000030700507007070090700b0700d0700f070110601306016050180501a0401d0401f0302103025020280202c0102e00026000190000000000000000000000000000000000000000000000000000000000
