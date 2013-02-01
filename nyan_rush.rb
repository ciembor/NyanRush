# encoding: utf-8

require "bundler/setup"
require "gaminator"

class NyanRush
  
  class Primitive < Struct.new(:x, :y, :char, :color); end

  ###########################################################

  class Matrix

    def initialize(strings, x, y)
      @data = []
      if strings.respond_to? :length
        @height = strings.length
        @width = strings[0].length
        @x = x
        @y = y

        for i in 0..(@height - 1)
          j = x
          strings[i].each_char do |char|
            primitive = Primitive.new(j, i + y, char, Curses::COLOR_WHITE)
            @data.push primitive
            j += 1
          end
        end
      end
    end

    def translate(x, y)
      @data.each do |primitive|
        primitive.x += x
        primitive.y += y
      end
      clear
    end

    def clear
      @data = @data.select { |primitive| primitive.x >= 0}
    end

    def append(chars, colors, x, y)
      for i in 0..(chars.length - 1)
        primitive = Primitive.new(x, y + i, chars[i], colors[i])
        @data.push primitive
      end
    end

    attr_accessor :data
    attr_reader :height

  end

  ###########################################################

  class Nyan

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    class Head

      def initialize(x, y, height)
        @x = x - 6
        @y = y - 2
        @height = height
        # http://evilzone.org/creative-arts/nyan-cat-ascii/
        @matrix = Matrix.new([
            ',-----',
            '|   /\_/\\',
            '|__( ^ .^)',
            '""  ""'
          ], @x, @y
        )
      end

      def moveUp
        if @y > 0 then
          @y -= 1
          @matrix.translate(0, -1)
        end
      end

      def moveDown
        if @y + @matrix.height < @height then
          @y += 1
          @matrix.translate(0, 1)
        end
      end

      def primitives
        @matrix.data
      end

      attr_reader :x, :y

    end
  
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    class Tail

      def initialize(head)
        @head = head
        @pattern = [
          'o',
          'o',
          'o',
          'o'
        ]
        @colors = [
          Curses::COLOR_RED,
          Curses::COLOR_YELLOW,
          Curses::COLOR_GREEN,
          Curses::COLOR_BLUE,
        ]
        @matrix = Matrix.new([''], @head.x - 1, @head.y)
      end

      def generate
        @matrix.translate(-1, 0)
        @matrix.clear
        @matrix.append(@pattern, @colors, @head.x - 1, @head.y)
      end

      def primitives
        @matrix.data
      end

    end

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    def initialize(x, y, height)
      @head = Head.new(x, y, height)
      @tail = Tail.new(@head)
    end
  
    def update
      @tail.generate
    end

    def primitives
      @head.primitives + @tail.primitives
    end

    def moveUp
      @head.moveUp
    end

    def moveDown
      @head.moveDown
    end

    attr_reader :head

  end

  ###########################################################

  class Wall

    def initialize(width, height)
      @scr_width = width
      @scr_height = height
      @top_pattern = []
      @bottom_pattern = []
      generate
      @top_matrix = Matrix.new(@top_pattern, @scr_width-1, 0)
      @bottom_matrix = Matrix.new(@bottom_pattern, @scr_width-1, @doors+4)
    end

    def generate
      @doors = Random.new.rand(0...(@scr_height-5))
      for i in 0...@doors
        @top_pattern.push("#")
      end
      for i in (@doors+4)...(@scr_height)
        @bottom_pattern.push("#")
      end
    end

    def update
      @top_matrix.translate(-1, 0)
      @bottom_matrix.translate(-1, 0)
    end

    def primitives
      @top_matrix.data + @bottom_matrix.data
    end

  end

  ###########################################################

  def initialize(width, height)
    @wall_counter = 0
    @score = 0
    @width = width
    @height = height
    @nyan = Nyan.new((width / 2).floor, (height / 2).floor, height)
    @wall = Wall.new(width, height)
  end

  def wait?
    false
  end

  def input_map
    {
      ?w => :moveUp,
      ?s => :moveDown,
      ?k => :moveUp,
      ?j => :moveDown,
      ?q => :exit,
    }
  end

  def sleep_time
    0.008
  end

  def objects
    @nyan.primitives + @wall.primitives
  end

  def check_collision
    if collision?
      exit
    end
  end

  def collision?
    @wall.primitives.each do |brick|
      @nyan.head.primitives.each do |primitive|
        if brick.y == primitive.y and brick.x == primitive.x
          return true
        end
      end
    end
    false
  end

  def tick
    @nyan.update
    @wall.update
    if @wall_counter > @width
      @wall_counter = 0
      @score += 1
      @wall = Wall.new(@width, @height)
    end
    check_collision
    @wall_counter += 1
  end

  def moveUp
    @nyan.moveUp
  end

  def moveDown
    @nyan.moveDown
  end

  def textbox_content
    if @score != 1
      "Nyanyanyanyan!!! %d walls." % @score
    else
      "Nyanyanyanyan!!! 1 wall."
    end
  end

  def exit
    Kernel.exit
  end

  def exit_message
    if @score != 1
      puts "Nyan's dead... %d walls." % @score
    else
      "Nyan's dead... 1 wall."
    end
  end

end

Gaminator::Runner.new(NyanRush).run
