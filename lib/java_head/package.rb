require 'pathname'


module JavaHead
  
  # The class to represent Java packages.
  # Packages are immutable and duplicate package names are not allowed.
  # To this end, the ::new method is private and packages are accessed using
  # the ::get method which checks the class's internal cache prior to creating a new object
  class Package

    # Construct a package
    # This method is private
    #
    # @param [String] name The Java name of the package
    def initialize(name)
      raise PackageException, "Package #{name} already exists" if @@stored[name.intern]
      
      # Test name
      raise PackageException, "Invalid package name #{name}" unless name.match FORMAT

      
      names = name.split('.') # An array of the package names, we will be using this a lot
      
      CLASSPATH.each do |base|
        absolute = base.join(*names)
        @path = absolute.realpath if absolute.exist? and absolute.directory?
      end
      raise PackageException, "Could not find directory for package #{name}" unless @path
      
      
      # Set superpackage
      @name = names.pop.freeze
      if names.empty?
        @superpackage = nil
      else
        @superpackage = self.class.get(names.join('.'))
      end
    end
    
    # getter methods for name, superpackage, path
    attr_reader :name,:superpackage,:path
    
    # recursively compute fullname using superpackage fullname
    #
    # @return [String] The package's full name, e.g. com.example.packagename
    def fullname
      return @name unless @superpackage
      "#{@superpackage.fullname}.#{@name}"
    end
    
    # to_s returns fullname
    alias to_s fullname
    
    # print useful fully-qualified name and path of class
    #
    # @return [String] A string that outlines the basic attributes of the object
    def inspect
      "[Java Package, name: #{fullname}, path: #{path}]"
    end
    
    # return a subpackage of the current package
    #
    # @param [String] name the name of the child package
    # @return [JavaHead::Package] the child package
    def subpackage(name)
      self.class.get("#{fullname}.#{name}")
    end
    
    # return a class within the current package
    #
    # @param [String] name the name of the class within the package
    # @return [JavaHead::Class] the child class
    def class(name=nil)
      return super() if name.eql? nil
      Class.new("#{fullname}.#{name}")
    end
    
    # get all classes in the current package
    #
    # @return [Array<JavaHead::Class>] all classes in the current package
    def classes
      Dir.chdir(@path) do
        Dir.glob('*.java').map! do |filename|
          self.class( filename.match(/^([A-Z][A-Za-z0-9]*)\.java$/)[1] )
        end
      end
    end
    
    # compile all classes in the package
    #
    # @return [JavaHead::Package] this package
    def compile
      classes.each { |c| c.compile }
      self
    end
    
    # Check if all the classes in this package are compiled
    #
    # @return [Boolean] Whether or not all classes are compiled
    def compiled?
      classes.each do |jclass|
        return false unless jclass.compiled?
      end
      true
    end
    
    # call #remove_class on all class files of the package
    #
    # @return [JavaHead::Package] the current value of this
    def remove_class
      classes.each { |c| c.remove_class }
      self
    end
    
    
    
    # returns #class(name) or #subpackage(name) depending on the format of name
    #
    # @param [String] name the name of the member element
    # @return [JavaHead::Package,JavaHead::Class] The child package or class
    def member(name)
      if name.match Class::FORMAT
        self.class(name)
      else
        subpackage(name)
      end
      
    end
    
    # > is a handy operator alias for member
    alias > member
    
    
    
    # The required format for all package names
    FORMAT = /^([a-z][a-z0-9]*\.)*[a-z_][a-z0-9_]*$/.freeze
    @@stored = Hash.new
    
    
    class << self
      private :new
      
      # Get the package that corresponds to name
      #
      # @param [String] name the name of the package
      # @return [JavaHead::Package] the package that corresponds to name
      def get(name)
        sym = name.intern
        return @@stored[sym] if @@stored[sym]
        package = new(name)
        @@stored[sym] = package
        package
      end
      
    end
    
  end
end