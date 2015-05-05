require 'dxruby'
require_relative '../ruby-ev3/lib/ev3'
require_relative 'director'
require_relative 'character'

class Robot
  LEFT_MOTOR = "D"
  RIGHT_MOTOR = "A"
  COLOR_SENSOR = "3"
  PORT = "COM3"
  MOTOR_SPEED = 50
  DISTANCE_SENSOR = "2"
  
  def initialize
    @past_color = "black"
    @current_direction = "right"
    @brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
    @red_count = 0
    @checked_time = Time.now.localtime
    @color_histry = []
    @displayed_color = "red"
  end



  def on_road?
    6 != @brick.get_sensor(COLOR_SENSOR, 2)
  end

  def check_color
    color = @brick.get_sensor(COLOR_SENSOR, 2)
    human_color(color)
  end

  def human_color(color_number)
    case color_number 
            
    when 0
      "no"
    when 1
      "black"
    when 2
      "blue"
    when 3
      "green"
    when 4 
      "yellow"
    when (5 || 7)
      "red"
    when 6
      "white"
    else
      "no"
    end
  end

  def block_color
    color = @brick.get_sensor(COLOR_SENSOR, 2)
    @color_histry << human_color(color)
    road_color = case color
    when 0
      C_BLACK
    when 1
      C_BLACK
    when 2
      C_BLUE
    when 3
      C_YELLOW
    when 4
      C_YELLOW
    when (5 || 7)
      C_RED
    when 6
      C_BLACK
    else
      C_BLACK
    end
    Image.new(30, 30, road_color)
  end

  def draw_block(color, c_block, block, map)
    if color != "no" && color != "white"
      c_block << block
    end
    map = Array.new(20) { [] }
    c_block_tmp = c_block.last(20)
    c_block_tmp.each_with_index do |e, i|
      map[0] << i
    end
    Window.draw_tile(50, 250, map, c_block_tmp, 1, 1, 25, 1)
  end

  def on_road_yellow?
    4 != @brick.get_sensor(COLOR_SENSOR, 2)
  end



  def go_right
    @brick.start(45, LEFT_MOTOR)
    @brick.start(60, RIGHT_MOTOR)
  end

  def go_left
    @brick.start(60, LEFT_MOTOR)
    @brick.start(45, RIGHT_MOTOR)
  end

  def sleep_sec(*motors, sec:0.15)
    sleep sec
    @brick.stop(false, *motors) 
  end
    
  def change_direction(*motors)
    if (@current_direction == "left")
      go_right
      @current_direction = "right"
    else
      go_left
      @current_direction = "left"
    end  
  end

  def keep_direction(*motors)
    if (@current_direction == "left")
      go_left
    else
      go_right
    end
  end

  def window_update(road_status, color, start_time, director)
    Window.draw_font(50, 600, "道情報 :", Font.new(32), {color: [0,0,0]})
    Window.draw_font(210, 600, "#{color}", Font.new(32), {color: color_code(color)})
    Window.draw_font(550, 600, "探索ポイント: #{@red_count}個発見", Font.new(32), {color:[0, 0, 0]})
    Window.draw_font(300, 500, "経過時間 #{timer(start_time)["min"]} : #{timer(start_time)["sec"]}", Font.new(32), {color:[0, 0, 0]})
    if road_status
      Window.draw_font(350, 600, "on road", Font.new(32) ,{color:[0, 0, 0]})
    else
      Window.draw_font(350, 600, "off road", Font.new(32),{color:[0, 0, 0]})
   end
   director.play
  end

  def color_code(color_string)
    case color_string
    when "black"
      [0, 0, 0]
    when "red"
      [255,0,0]
    when "blue"
      [0,0,153]
    when "yellow"
      [255,255,0]
    when "white"
      [204,204,204]
    when "green"
      [0,153,0]
    else 
      [0,0,0]
    end
  end

  def check_red_count(color)
    if (@past_color == "red" && color != "red") && (Time.now.localtime - @checked_time > 3)
      @red_count += 1 
      @checked_time = Time.now.localtime
    end
  end

  def timer(start_time)
    now_time = Time.now
    e_time = now_time - start_time
    e_min = (e_time / 60).to_i
    e_sec = (e_time % 60).to_i
    {"min" =>  e_min, "sec" => e_sec}
  end

  def run 
    Window.caption = "RubyCamp2015"
    Window.width = 900
    Window.height = 700

    begin
      puts "starting..."
      
      @brick.connect
      puts "connected..."
      motors = [LEFT_MOTOR, RIGHT_MOTOR]
      @brick.run_forward(*motors)
      @brick.reverse_polarity(*motors)
      y_pos = 100
      c_block = []
      map = [[]]
      start_time = Time.now
      director = Director.new

      Window.loop do

        Window.draw(0, 0, Image.load("images/background.png"))
        break if Input.keyDown?( K_SPACE )  
        
        color = check_color
        road_status = on_road?
        block = block_color

        draw_block(color, c_block, block, map)

        window_update(road_status, color, start_time, director)
        
        if (@past_color == "yellow" && color != "yellow")
          change_direction(*motors)
          sleep_sec(*motors)
        elsif (@past_color != "white" && color == "white")
          change_direction(*motors)
          sleep_sec(*motors)
        else
          keep_direction(*motors)
          sleep_sec(*motors)
        end

        check_red_count(color)

        @past_color = color        
      end

    ensure
      puts "closing..."
      @brick.stop(false, *motors)
      @brick.clear_all
      @brick.disconnect
      puts "finished..."
    end
  end  
end

ev3 = Robot.new
ev3.run