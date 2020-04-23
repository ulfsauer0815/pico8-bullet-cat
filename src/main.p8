pico-8 cartridge // http://www.pico-8.com
version 21
__lua__
-- Bullet Cat
-- by Ulf Sauer


local PS_LEFT=3
local PS_RIGHT=4
local PS_UP=1
local PS_DOWN=2
local FRAME_RATE=30

local SND_JUMP=0

local PLAYER_INIT_POS={x=64, y=31}

local debug=true
local draw_bounds=false

local JUMP_ENERGY=1.5

local player
local enemy1
local enemy2
local objects
local enemies


function _init()
	player=create_player(PLAYER_INIT_POS.x,PLAYER_INIT_POS.y)
	enemy1=create_enemy(10,49)
	enemy2=create_enemy(80,49)
	objects={player, enemy1, enemy2}
	enemies={enemy1, enemy2}

	foreach(objects, function(o) if (o.init) then o:init() end end)
end

function _update()
	foreach(objects, function(o) if o.update then o:update() end end)
	for enemy in all(enemies) do
		if (player:intersects(enemy)) then
			player:hit()
		end
	end
	if(btnp(5)) then
		draw_bounds=not draw_bounds
	end
end


function _draw()
	cls()

	-- debug
	if (debug) then
		print(out)
		print(player.hit_timer)
	end

	-- map
	map(0,0,0,0,16,16)

	-- objects
	foreach(objects, function(o) if (o.draw) then o:draw() end end)

	-- ui
	draw_hearts(player.lives)
	if (player:is_invincible()) then
		print('get ready!', 128/2-12*2,40, 1)
	end
end

function draw_hearts(n)
	for y=0,(n-1)*8,8 do
		spr(48,y,25)
	end
end


function create_player(x,y)
	return {
		x=x,
		y=y,
		width=4,
		height=8,
		sprite=PS_UP,
		jump_energy=0,
		move_energy=0.4,
		vy=0,
		vx=0,
		gravity=0.1,

		lives=5,
		hit_timer=0,
		invincibility_period=3*30,

		hit=function(this)
			if (not this:is_invincible()) then
				this.lives-=1
				this.hit_timer=this.invincibility_period
			end
		end,

		is_invincible=function(this)
			return this.hit_timer>0
		end,

		on_ground=function(this)
			return this.y >= 56
		end,

		intersects=function(this, o)
			local bounds=get_bounds(this)
			local o_bounds=get_bounds(o)
			local x_intersects=bounds.xe > o_bounds.xs and bounds.xs <= o_bounds.xe
			local y_intersects=bounds.ye > o_bounds.ys and bounds.ys <= o_bounds.ye

			return x_intersects and y_intersects
		end,

		controls_update=function(this)
			if(btn(2)) then
				this.sprite=PS_DOWN
			end
			if(btn(3)) then
				this.sprite=PS_UP
			end
			if(btn(0)) then
				this.sprite=PS_LEFT
				this.vx=max(-2, this.vx-this.move_energy)
			elseif(btn(1)) then
				this.sprite=PS_RIGHT
				this.vx=min(2, this.vx+this.move_energy)
			else
				if (this.vx <= this.move_energy and this.vx >= -this.move_energy) then
					this.vx=0
				else
					this.vx=this.vx-sgn(this.vx)*this.move_energy
				end
			end
			if(btnp(4) and this:on_ground()) then
				this.vy=-JUMP_ENERGY
				sfx(SND_JUMP)
			end
		end,

		init=function(this)
			this.hit_timer=this.invincibility_period
		end,

		update=function(this)
			this:controls_update()
			this.x+=this.vx
			this.y+=this.vy
			this.vy=this.vy+this.gravity

			if (this:on_ground()) then
				this.vy=0
			end

			if (this:is_invincible()) then
				this.hit_timer-=1
			end
		end,

		draw=function(this)
			print(this.hit_timer..' '..this.invincibility_period)
			local frequency_correction=2
			local frequency=(this.hit_timer/this.invincibility_period)*5+frequency_correction
			local flicker=this.hit_timer / frequency % 1 < 0.5
			if (this:is_invincible() and not flicker) then
				pal(9,7)
			end
			local fraction=this.invincibility_period/8
			visibility=max(0,this.hit_timer-(this.invincibility_period-fraction))/fraction
			spr(this.sprite,this.x,this.y,1,1-visibility)
			pal()
			if (draw_bounds) then
				local bounds=get_bounds(this)
				rect(bounds.xs, bounds.ys, bounds.xe, bounds.ye, 8)
			end
		end,
	}
end

get_bounds=function(this)
	local y_off=this.bounds_y_offset or 0
	local x_off=this.bounds_x_offset or 0
	return {
		xs=this.x+(8-this.width)/2 + x_off,
		xe=this.x+this.width+(8-this.width)/2-1 + x_off,
		ys=this.y + y_off,
		ye=this.y+this.height-1 + y_off,
	}
end

function create_enemy(x,y)
	return {
		x=x,
		y=y,
		bounds_y_offset=1,
		width=8,
		height=7,
		sprite=32,
		sprite_flip=true,
		vx=2,
		vy=0,
		gravity=0.2,

		on_ground=function(this)
			return this.y >= 56
		end,

		update=function(this)
			if (this.x+this.width/2 >= 128) then
				this.vx = this.vx*-1
			end
			if (this.x <= 0) then
				this.vx = this.vx*-1
			end

			if (this:on_ground()) then
				this.vy=0
			end
			this.x+=this.vx
			this.y+=this.vy
			this.vy=this.vy+this.gravity
			this.sprite_flip=this.vx>=0
		end,

		draw=function(this)
			spr(this.sprite,this.x,this.y,1,1,this.sprite_flip)
			if (draw_bounds) then
				local bounds=get_bounds(this)
				rect(bounds.xs, bounds.ys, bounds.xe, bounds.ye, 8)
			end
		end
	}
end

__gfx__
00000000005555000055550000555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005555000055550000555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700022922200299992000229500005922000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000009999000099990000999900009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000009999000099990000999900009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006666000066660000666000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006066000066060000606600006606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004004000040040000040400004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02288688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82288688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08e88888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08ee8888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08eee888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008ee880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333b3333344444444444494449444944444449444cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
333333333bb3333344444444444494449444944444449444ccccccccccccccc7777c7777777c77777ccccccc0000000000000000000000000000000000000000
333333333b3333b344444444444494444444944444449444ccccccccccccc7777777777c7777777777cccccc0000000000000000000000000000000000000000
333333333bb333b344444444444994444449944444499444ccccccccccccc777777777cc777777777ccccccc0000000000000000000000000000000000000000
3333333333333bb344444444444994444449944444499444ccccccccccccccccccccccccc77777cccccccccc0000000000000000000000000000000000000000
3333333333333b3344444444449994444444444444999444ccccccccccccccccccccccccccccc7cccccccccc0000000000000000000000000000000000000000
333333333bb33b3344444444499494444444444449949444cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
333333333333333344444444994494444444444499449444cccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000
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
4242424242434242424542424442424200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242424242444242424242424242424200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242454242424242424242424242454200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010000030700507007070090700b0700d0700f070110601306016050180501a0401d0401f0302103025020280202c0102e00026000190000000000000000000000000000000000000000000000000000000000
