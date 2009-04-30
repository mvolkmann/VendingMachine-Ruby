# These are tests for an implementation of the Vending Machine specification
# from the St. Louis Lambda Lounge.  See the "specification" link at
# http://groups.google.com/group/lambda-lounge/web/language-shootout
# author: R. Mark Volkmann, Object Computing, Inc.

require 'stringio'
require 'test/unit'
require 'vendingmachine'

class VendingMachineTest < Test::Unit::TestCase

  def setup
    @machine = create_and_fill_machine
    @old_out, $stdout = $stdout, StringIO.new
  end

  def teardown
    $stdout = @old_out
  end

  def test_change
    @machine.change
    expected = <<-HERE
machine holds:
5 nickels
3 dimes
4 quarters
2 dollars
    HERE
    assert_equal expected, $stdout.string
  end

  def test_cr
    # Add $1.50.
    @machine.command('n')
    @machine.command('d')
    @machine.command('d')
    @machine.command('q')
    @machine.command('1')

    # Since the machine holds additional quarters,
    # it makes change with fewer coins.
    @machine.cr
    expected = <<-HERE
1
q
q
    HERE
    assert_equal expected, $stdout.string
  end

  def test_help
    @machine.help
    expected = /^Commands are:/
    assert expected =~ $stdout.string
  end

  def test_inserted
    @machine.inserted
    expected = 'amount inserted is $0.00'
    assert_equal expected, $stdout.string.chomp

    $stdout.string = ''
    @machine.command('1')
    @machine.command('q')
    @machine.inserted
    expected = 'amount inserted is $1.25'
    assert_equal expected, $stdout.string.chomp
  end

  def test_items
    @machine.items
    expected = <<-HERE
A - 3 Juicy Fruit $0.65
B - 2 Baked Lays $1.00
C - 4 Pepsi $1.50
    HERE
    assert_equal expected, $stdout.string
  end

  def test_buy_with_insufficient_change
    @machine.command('q')
    @machine.command('q')
    @machine.command('n')
    @machine.command('A')
    expected = <<-HERE
insert $0.10 more
    HERE
    assert_equal expected, $stdout.string
  end

  def test_buy_with_exact_change
    @machine.command('q')
    @machine.command('q')
    @machine.command('d')
    @machine.command('n')
    @machine.command('A')
    expected = <<-HERE
A
    HERE
    assert_equal expected, $stdout.string
  end

  def test_buy_with_excess_change
    @machine.command('1')
    @machine.command('1')
    @machine.command('A')
    expected = <<-HERE
1
q
d
A
    HERE
    assert_equal expected, $stdout.string
  end

  def test_bad_change
    machine = Machine.new
    machine.add_item('A', 'Juicy Fruit', 0.65, 1)
    machine.add_money(0.25, 1)
    machine.command('q')
    machine.command('q')
    machine.command('q')
    machine.command('A')
    expected = "use correct change\n"
    assert_equal expected, $stdout.string
  end

end
