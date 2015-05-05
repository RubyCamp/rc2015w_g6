class Character
  def initialize(x, y, image_file)
    @x, @y = x, y
    @image = Image.load(image_file)
    @dx = 5
  end

  def move
    @x += @dx
    @dx = -@dx if @x > (Window.width - @image.width) || @x < 0
  end

  def draw
    Window.draw(@x, @y, @image)
  end
end