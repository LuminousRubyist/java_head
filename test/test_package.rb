require 'minitest/autorun'
require 'java_head'

class TestPackage < MiniTest::Test
  def setup
    Dir.chdir "#{__dir__}/src" do
      @package = JavaHead::Package.get 'com.example'
    end
  end
  
  def test_package_should_match_directory
    assert_equal @package.path, Pathname.new("#{__dir__}/src/com/example")
    assert_equal @package.superpackage, JavaHead::Package.get('com')
    assert_equal @package.subpackage('projects'), JavaHead::Package.get('com.example.projects')
  end
  
  def test_safe_package_should_compile
    pkg = @package > 'projects.safe'
    pkg.compile
    assert pkg.compiled?
    pkg.remove_class
    refute pkg.compiled?
  end
  
  def test_broken_package_should_not_compile
    pkg = @package > 'projects.broken'
    assert_raises JavaHead::Exceptions::CompilerException do
      pkg.compile
    end
    refute pkg.compiled?
  end
  
  
end
