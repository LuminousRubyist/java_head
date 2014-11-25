require 'minitest/autorun'
require 'java_head'

class TestRegex < MiniTest::Test
  
  def test_package_format
    good = ['com.example.asdf','_name','hello.asdf']
    bad  = ['com.example.','Name','arg-','-hello.world']
    
    good.each do |name|
      assert name.match(JavaHead::Package::FORMAT)
    end
    
    bad.each do |name|
      refute name.match(JavaHead::Package::FORMAT)
    end
  end
  
  def test_class_format
    good = ['com.example.Name','A','Map','a.b.c.d.e.f.Name']
    bad  = ['3Package','com.example.-asdf','hello','A-name']
    
    good.each do |name|
      assert name.match(JavaHead::Class::FORMAT)
    end
    
    bad.each do |name|
      refute name.match(JavaHead::Class::FORMAT)
    end
  end
  
  def test_argument_format
    good = ['arg1','hello','-g:none','a=1','asdf="d"']
    bad  = [';asdf','%%%']
    
    good.each do |arg|
      assert arg.match(JavaHead::Class::ARGFORMAT)
    end
    bad.each do |arg|
      refute arg.match(JavaHead::Class::ARGFORMAT)
    end
  end
  
  
end