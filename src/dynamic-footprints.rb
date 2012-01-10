#==============================================================================
# ** Dynamic Footprints
#------------------------------------------------------------------------------
# Wachunga
# version 1.0
# 2005-11-07
# See https://github.com/Wachunga/rmxp-dynamic-footprints for details
#==============================================================================

#----------------------------------------------------------------------
# Footprints for six situations (down->up, left->right, down->left,
# left->up, up->right and right->down) are required (twelve for
# directional footprints). See the provided footprints template
# (footprints_template.png) for specific details, noting
# that the right half of the template can be empty if using the default
# of non-directional footprints (i.e. leaving FP_DIRECTIONAL = false).
FP_FILE = "footprints_default"
#----------------------------------------------------------------------
# FP_DIRECTIONAL specifies whether there are direction-specific
# footprints (e.g. footprints from player moving up are different
# from those left when player is moving down)
FP_DIRECTIONAL = false
#----------------------------------------------------------------------
# Terrain tag(s) as set in the database
FP_TAG = 1
#----------------------------------------------------------------------
# How much time elapses before footprints begin to fade
FP_BEFORE_FADE_TIME = 100
# After beginning to fade, how long the fading process actually takes
FP_FADE_TIME = 100
# Note: it's possible to maintain footprints indefinitely (with
# FP_FADE_TIME = 0), but if the player opens a menu or changes maps,
# the footprints won't be saved. To allow them to persist even then,
# use Near's Dynamic Maps script (slight modifications would be needed).
#----------------------------------------------------------------------
# tilemap indexes (do not modify)
# regular:
FP_DU = 384
FP_LR = 385
FP_DL = 386
FP_LU = 387
FP_UR = 388
FP_RD = 389
# directional:
FP_UD = 512
FP_RL = 513
FP_DR = 514
FP_RU = 515
FP_UL = 516
FP_LD = 517

#----------------------------------------------------------------------

class Spriteset_Map
 attr_accessor :footprints  
 attr_accessor :fp_tilemap 
 def initialize
   @viewport1 = Viewport.new(0, 0, 640, 480)
   @viewport2 = Viewport.new(0, 0, 640, 480)
   @viewport3 = Viewport.new(0, 0, 640, 480)
   @viewport2.z = 200
   @viewport3.z = 5000
   @tilemap = Tilemap.new(@viewport1)
   @tilemap.tileset = RPG::Cache.tileset($game_map.tileset_name)
   for i in 0..6
     autotile_name = $game_map.autotile_names[i]
     @tilemap.autotiles[i] = RPG::Cache.autotile(autotile_name)
   end
   @tilemap.map_data = $game_map.data
   @tilemap.priorities = $game_map.priorities
   @panorama = Plane.new(@viewport1)
   @panorama.z = -1000
   @fog = Plane.new(@viewport1)
   @fog.z = 3000
   @character_sprites = []
   for i in $game_map.events.keys.sort
     sprite = Sprite_Character.new(@viewport1, $game_map.events[i])
     @character_sprites.push(sprite)
   end
   @character_sprites.push(Sprite_Character.new(@viewport1, $game_player))
   @weather = RPG::Weather.new(@viewport1)
   @picture_sprites = []
   for i in 1..50
     @picture_sprites.push(Sprite_Picture.new(@viewport2,
       $game_screen.pictures[i]))
   end
   @timer_sprite = Sprite_Timer.new

   # Dynamic Footprints additions begin
   @footprints = []
   fp_tileset = FP_DIRECTIONAL ? Bitmap.new(256,1024) : Bitmap.new(256,512)
   # make a column for each footprint image
   # right -> down
   fp_tileset.blt(160, 0, RPG::Cache.tileset(FP_FILE), Rect.new(0, 0, 32, 32))
   # up -> right
   fp_tileset.blt(128, 0, RPG::Cache.tileset(FP_FILE), Rect.new(0, 32, 32, 32))   
   # left -> right   
   fp_tileset.blt(32, 0, RPG::Cache.tileset(FP_FILE), Rect.new(0, 64, 32, 32))    
   # down -> left
   fp_tileset.blt(64, 0, RPG::Cache.tileset(FP_FILE), Rect.new(32, 0, 32, 32))
   # left -> up
   fp_tileset.blt(96, 0, RPG::Cache.tileset(FP_FILE), Rect.new(32, 32, 32, 32))   
   # down -> up
   fp_tileset.blt(0, 0, RPG::Cache.tileset(FP_FILE), Rect.new(32, 64, 32, 32))

   # fill out each column, making copies of the image with decreasing opacity
   0.step(5*32, 32) do |x|
     opacity = 255
     0.step(15*32, 32) do |y|
       fp_tileset.blt(x, y, fp_tileset, Rect.new(x, 0, 32, 32), opacity)
       opacity -= 16
     end
   end

   if FP_DIRECTIONAL
     # down -> right
     fp_tileset.blt(160, 512, RPG::Cache.tileset(FP_FILE), Rect.new(64, 0, 32, 32))
     # right -> up
     fp_tileset.blt(128, 512, RPG::Cache.tileset(FP_FILE), Rect.new(64, 32, 32, 32))   
     # right -> left
     fp_tileset.blt(32, 512, RPG::Cache.tileset(FP_FILE), Rect.new(64, 64, 32, 32))    
     # left -> down
     fp_tileset.blt(64, 512, RPG::Cache.tileset(FP_FILE), Rect.new(96, 0, 32, 32))
     # up -> left
     fp_tileset.blt(96, 512, RPG::Cache.tileset(FP_FILE), Rect.new(96, 32, 32, 32))   
     # up -> down
     fp_tileset.blt(0, 512, RPG::Cache.tileset(FP_FILE), Rect.new(96, 64, 32, 32))
     
     0.step(5*32, 32) do |x|
       opacity = 255
       512.step(32*32, 32) do |y|
         fp_tileset.blt(x, y, fp_tileset, Rect.new(x, 512, 32, 32), opacity)
         opacity -= 16
       end
     end   
   end
   
   @fp_tilemap = Tilemap.new(@viewport1)   
   @fp_tilemap.tileset = fp_tileset
   @fp_tilemap.map_data = Table.new($game_map.width, $game_map.height, 3)
   # end Dynamic Footprints additions
   
   update
 end

 alias fp_dispose dispose
 def dispose
   @fp_tilemap.dispose
   fp_dispose
 end

 alias fp_update update
 def update
   @fp_tilemap.ox = $game_map.display_x / 4
   @fp_tilemap.oy = $game_map.display_y / 4
   @fp_tilemap.update
   unless FP_FADE_TIME == 0
     for fp in @footprints
       if fp.time > 1
         fp.time -= 1
         if fp.fade and (FP_FADE_TIME - fp.time) % (FP_FADE_TIME/16.0) < 1
           @fp_tilemap.map_data[fp.x,fp.y,fp.z] += 8
         end
       else
         if not fp.fade
           # begin fading
           fp.time = FP_FADE_TIME
           fp.fade = true
         else        
           @fp_tilemap.map_data[fp.x,fp.y,fp.z] = 0
           @footprints.delete(fp)
         end
       end
     end
   end
   fp_update
 end
 
  def show_footprints(fp_index,fp_x,fp_y)
    # start with first layer, then stack footprints as necessary
    fp_z = 0
    if @fp_tilemap.map_data[fp_x,fp_y,fp_z] == 0
     @fp_tilemap.map_data[fp_x,fp_y,fp_z] = fp_index
    else
     fp_z = 1
     if @fp_tilemap.map_data[fp_x,fp_y,fp_z] == 0
       @fp_tilemap.map_data[fp_x,fp_y,fp_z] = fp_index
     else
       fp_z = 2
       if @fp_tilemap.map_data[fp_x,fp_y,fp_z] != 0
         # delete the existing footprint at these coords from the list
         # (to prevent having multiples)
         for i in @footprints.reverse
           if i.x == fp_x and i.y == fp_y and i.z == fp_z
             @footprints.delete(i)
             break
           end
         end
       end
       @fp_tilemap.map_data[fp_x,fp_y,fp_z] = fp_index
     end
    end
    @footprints.push(Footprint.new(fp_x,fp_y,fp_z))     
  end  

end

#-------------------------------------------------------------------------------

class Game_Event < Game_Character
  alias fp_ge_init initialize
  def initialize(map_id, event) 
   fp_ge_init(map_id, event)
   if @event.name.upcase.include?('<NOFP>')
     @fp_id = nil
   end
  end
end

#-------------------------------------------------------------------------------

class Game_Character

 alias fp_gc_init initialize
 def initialize
   fp_gc_init
   # 1st argument = second last x/y
   # 2nd argument = last x/y
   @last_x = [0,0]
   @last_y = [0,0]
   @fp_id = 0 # default footprints
 end

 def footprints
   # determine which prints to draw and where
   if terrain_tag(@last_x[1],@last_y[1]) != FP_TAG
     return
   end
   fp_index = nil
   # left
   if @x > @last_x[1]
     if @last_y[1] > @last_y[0]
       fp_index = FP_UR
     elsif @last_y[1] < @last_y[0]
       fp_index = FP_DIRECTIONAL ? FP_DR : FP_RD
     else
       fp_index = FP_LR
     end
   else
     # right
     if @x < @last_x[1]
       if @last_y[1] > @last_y[0]
         fp_index = FP_DIRECTIONAL ? FP_UL : FP_LU
       elsif @last_y[1] < @last_y[0]
         fp_index = FP_DL
       else
         fp_index = FP_DIRECTIONAL ? FP_RL : FP_LR
       end
     else
       # up
       if @y < @last_y[1]
         if @last_x[1] > @last_x[0]
           fp_index = FP_LU
         elsif @last_x[1] < @last_x[0]
           fp_index = FP_DIRECTIONAL ? FP_RU : FP_UR
         else
           fp_index = FP_DU
         end
       # down
       elsif @y > @last_y[1]
         if @last_x[1] > @last_x[0]
           fp_index = FP_DIRECTIONAL ? FP_LD : FP_DL
         elsif @last_x[1] < @last_x[0]
           fp_index = FP_RD
         else
           fp_index = FP_DIRECTIONAL ? FP_UD : FP_DU
         end
       end
     end
   end
   if fp_index != nil
     fp_x = @last_x[1]
     fp_y = @last_y[1]
     $scene.spriteset.show_footprints(fp_index,fp_x,fp_y)
   end
 end

  def moveto(x, y)
    @x = x
    @y = y
    @real_x = x * 128
    @real_y = y * 128
    if @fp_id != nil
      # track the last positions
      @last_x = [@x,@x]
      @last_y = [@y,@y]
    end
  end 
 
  def increase_steps
    @stop_count = 0
    # show footprints if enabled for this character
    if @fp_id != nil and $scene.is_a?(Scene_Map)
      footprints
      # track the last positions
      @last_x.shift
      @last_x.push(@x)   
      @last_y.shift
      @last_y.push(@y)   
    end
  end

  def terrain_tag(x=@x,y=@y)
    return $game_map.terrain_tag(x, y)
  end

  def update_jump
    @jump_count -= 1
    @real_x = (@real_x * @jump_count + @x * 128) / (@jump_count + 1)
    @real_y = (@real_y * @jump_count + @y * 128) / (@jump_count + 1)
    if @fp_id != nil and @jump_count == 0
      # track the last positions
      @last_x = [@x,@x]
      @last_y = [@y,@y]      
    end
  end  
  
end

#-------------------------------------------------------------------------------

class Scene_Map
  attr_reader :spriteset
 
  # only change is a couple of (commented) sections to prevent teleporting
  # within same map from losing footprints when the spriteset is recreated
  def transfer_player
    $game_temp.player_transferring = false
    if $game_map.map_id != $game_temp.player_new_map_id
      $game_map.setup($game_temp.player_new_map_id)
    else # Dynamic Footprints
      fp = @spriteset.footprints
      md = @spriteset.fp_tilemap.map_data
    end
    $game_player.moveto($game_temp.player_new_x, $game_temp.player_new_y)
    case $game_temp.player_new_direction
    when 2
      $game_player.turn_down
    when 4
      $game_player.turn_left
    when 6
      $game_player.turn_right
    when 8
      $game_player.turn_up
    end
    $game_player.straighten
    $game_map.update
    @spriteset.dispose
    @spriteset = Spriteset_Map.new
    if fp != nil or md != nil # Dynamic Footprints
      @spriteset.footprints = fp
      @spriteset.fp_tilemap.map_data = md
    end
    if $game_temp.transition_processing
      $game_temp.transition_processing = false
      Graphics.transition(20)
    end
    $game_map.autoplay
    Graphics.frame_reset
    Input.update
  end 
end

#-------------------------------------------------------------------------------

class Footprint
 attr_reader :x
 attr_reader :y
 attr_reader :z
 attr_accessor :time
 attr_accessor :fade

 def initialize(x,y,z)
   @x = x
   @y = y
   @z = z
   @time = FP_BEFORE_FADE_TIME
   @fade = false
 end

end
