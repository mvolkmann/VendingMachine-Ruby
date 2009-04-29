# This is an implementation of the Vending Machine specification
# from the St. Louis Lambda Lounge.  See the "specification" link at
# http://groups.google.com/group/lambda-lounge/web/language-shootout
# author: R. Mark Volkmann, Object Computing, Inc.

class Item
  attr_accessor :quantity
  attr_reader :desc, :price

  def initialize(desc, price, quantity)
    @desc, @price, @quantity = desc, price, quantity
  end
end

class Money
  @@codes = {0.05=>'n', 0.10=>'d', 0.25=>'q', 1.00=>'1'}
  @@names = {0.05=>'nickel', 0.10=>'dime', 0.25=>'quarter', 1.00=>'dollar'}

  def self.code(value); @@codes[value]; end
  def self.currency(amount); "$#{'%.2f' % amount}"; end
  def self.name(value); @@names[value]; end

  def self.to_s(value, quantity)
    s = "#{quantity} #{Money.name(value)}"
    s += 's' if quantity > 1
  end
end

class Machine

  def self.make_change(amount, money_map, change=[])
    # For each key in money_map in reverse sorted order ...
    money_map.keys.sort.reverse.each do |value|

      # If this value completes a solution, return the solution.
      if (value - amount).abs < 1e-7
        return change << value

      # If this value could possibly be part of a solution ...
      elsif value < amount
        # Create a new money map where
        # a coin with the current value is removed.
        new_money_map = money_map.clone
        Machine.remove_coin(new_money_map, value)

        new_change = Machine.make_change(
          amount - value, new_money_map, change + [value])

        # If a solution was found, return it.
        return new_change if new_change
      end
    end

    nil # no solution found
  end

  # Removes a coin from a given money map.
  def self.remove_coin(money_map, value)
    quantity = money_map[value]
    if quantity == 1
      money_map.delete(value)
    else
      money_map[value] = quantity - 1
    end
  end

  def initialize
    @inserted = 0
    @items = {}
    @money_map = Hash.new(0) # default value for missing keys is 0
  end

  # Adds items that are available for purchase.
  def add_item(selector, desc, price, quantity)
    item = @items[selector]
    if item
      # The item already exists, so just increase the quantity.
      item.quantity += quantity
    else
      # The item doesn't already exists so create it.
      @items[selector] = Item.new(desc, price, quantity)
    end
  end

  # Adds money that is available for making change.
  def add_money(value, quantity)
    @money_map[value] += quantity
  end

  # Reports the change available in the machine.
  def change
    puts 'machine holds:'
    @money_map.each do |value, quantity|
      puts Money.to_s(value, quantity)
    end
  end

  # Takes a command string and executes the corresponding method.
  def command(str)
    str = 'dollar' if str == '1'
    send str.to_sym
  end

  # Coin return.
  # Returns true if successful and
  # false if it couldn't make correct change.
  def cr
    change = Machine.make_change(@inserted, @money_map)
    if change
      change.each do |value|
        puts Money.code(value)
        Machine.remove_coin(@money_map, value)
      end
      @inserted = 0
    end
    change
  end

  def help
    puts 'Commands are:'
    puts '  help - show this help'
    puts '  exit or quit - exit the application'
    puts '  change - list change available'
    puts '  items - list items available'
    puts '  inserted - show amount inserted'
    puts '  cr - coin return'
    puts '  n - enter a nickel'
    puts '  d - enter a dime'
    puts '  q - enter a quarter'
    puts '  1 - enter a dollar bill'
    puts '  uppercase letter - buy item with that selector'
  end

  # Reports the amount of money that has been inserted into the machine
  # and can be used to make a purchase.
  def inserted
    puts "amount inserted is #{Money.currency(@inserted)}"
  end

  # Reports the items in the machine that are available for purchase.
  def items
    @items.each do |selector, item|
      puts "#{selector} - #{item.quantity} #{item.desc} " +
        Money.currency(item.price)
    end
  end

  # Handles item selection codes like A, B, C, ...
  def method_missing(symbol, *args, &block)
    selector = symbol.to_s
    if @items[selector]
      purchase selector
    else
      puts "no such command \"#{cmd}\""
    end
  end

  def process_commands
    puts 'Enter commands such as "help".'
    loop do
      print '> '
      cmd = gets.chomp
      break if ['exit', 'quit'].include?(cmd)
      command(cmd) unless cmd.empty?
    end
  end

  def purchase(selector)
    item = @items[selector]

    if item.quantity > 0
      excess = @inserted - item.price
      if excess >= 0
        @inserted -= item.price
        # If paying with exact change or correct change can be made ...
        if excess == 0 || cr
          item.quantity -= 1
          items.delete(selector) if item.quantity == 0
          puts selector
        else
          puts 'use correct change'
        end
      else
        puts "insert #{Money.currency(-excess)} more"
      end
    else
      puts 'sold out'
    end
  end

  # These four methods handle insertion of money.
  def n; insert 0.05; end
  def d; insert 0.10; end
  def q; insert 0.25; end
  def dollar; insert 1.00; end

  private

  # Inserts money to be used for a purchase.
  def insert(value)
    @money_map[value] += 1
    @inserted += value
  end
end

def create_and_fill_machine
  machine = Machine.new
  machine.add_item('A', 'Juicy Fruit', 0.65, 3)
  machine.add_item('B', 'Baked Lays', 1.00, 2)
  machine.add_item('C', 'Pepsi', 1.50, 4)
  machine.add_money(0.05, 5)
  machine.add_money(0.10, 3)
  machine.add_money(0.25, 4)
  machine.add_money(1.00, 2)
  machine
end

if $PROGRAM_NAME == __FILE__
  machine = create_and_fill_machine
  machine.process_commands
end
