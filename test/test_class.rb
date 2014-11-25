require 'minitest/autorun'
require 'colorize'
require 'java_head'


class TestClass < MiniTest::Test
  
  def setup
    JavaHead::CLASSPATH.push( Pathname.new("#{__dir__}/src") )
    @safe = JavaHead::Class.new('com.example.projects.Safe')
    @broken = JavaHead::Class.new('com.example.projects.Broken')
  end
  
  def test_safe_class_should_compile
    @safe.compile
    assert @safe.compiled?
    @safe.remove_class
    refute @safe.compiled?
  end
  
  def test_safe_class_should_run
    Dir.chdir 'test/src' do
      output = @safe.run('Input')
      assert_equal output.chomp, 'Input'
    end
  end
  
  def test_broken_class_should_not_compile
    assert_raises JavaHead::CompilerException do
      puts
      puts 'THE FOLLOWING JAVA ERROR IS EXPECTED, WE ARE TESTING THAT BROKEN CLASSES SHOULD NOT COMPILE'
      @broken.compile() # Do not generate compiler warnings
    end
    @broken.remove_class
    refute @broken.compiled?
  end
  
  
  
end