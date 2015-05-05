class Director
  def initialize
    @char = Character.new(0, 300, "images/car.png")
  end

  def play
    @char.move
    @char.draw
  end
end