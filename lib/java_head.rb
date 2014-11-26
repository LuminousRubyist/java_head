
# Version info
require "java_head/version"

# A file to represent java Packages and Classes
# requires pathnames
require 'pathname'

# The namespace for the classes
module JavaHead
  
  # Methods in the eigenclass of Java
  class << self
    # Find a package using Package.get
    #
    # @param [String] name the name of the package to be found
    # @return [JavaHead::Package] the package corresponding to name
    def package(name)
      Package.get(name)
    end
    
    # Returns the class with no arguments
    # Returns a new class with the given name if an argument is passed
    #
    # @param [String] name the name of the class to initialize
    # @return [JavaHead::Class] the resulting class
    def class(name = nil)
      return super() if name.eql? nil
      Class.new(name)
    end
    
    # Creates either a class or a package
    # depending on the format of the given string
    #
    # @param [String] name the name of the child element
    # @return [JavaHead::Package, JavaHead::Class] the resulting package or class object
    def member(name)
      if name.match Class::FORMAT
        self.class(name)
      else
        package(name)
      end
    end
    
    # > is an alias for member
    alias > member

    # Try to load the file const_name if the constant cannot be found
    #
    # @param [String] const_name
    # @return [Regexp,Array,Class] the value of the constant const_name in the namespace of JavaHead
    def const_missing(const_name)
      require "#{__dir__}/java_head/#{const_name}.rb"
      return const_get const_name
    rescue LoadError
      super
    end

  end


 
  
end

class String
  # This method allows more convenience in initializing JavaHead objects.
  # For instance:
  # Java::Package.get('com.example.shapes')
  # to be written:
  # 'com.example.shapes'.java
  # and
  # Java::Class.new('com.example.shapes.Circle')
  # to be written as
  # 'com.example.shapes.Circle'.java
  #
  # @return [JavaHead::Package, JavaHead::Class] JavaHead.member(self)
  def java
    JavaHead.member self
  end
end
