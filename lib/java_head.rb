
# Version info
require "java_head/version"

# A file to represent java Packages and Classes
# requires pathnames
require 'pathname'

# The namespace for the classes
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
  
  # Class to represent Java Classes
  class Class
    # Construct a new Class object
    #
    # @param [String] name the full name of the class
    def initialize(name)
      raise ClassException, "Invalid class name #{name}" unless name.match FORMAT
      
      names = name.split('.')
      @name = names.pop.freeze
      @package = Package.get(names.join('.'))
      @path = @package.path.join("#{@name}.java")
      
      raise ClassException, "Location not found for class #{name}" unless @path.exist? and @path.file?
    end
    # name, package, and path are publicly visible
    attr_reader :name, :package, :path
    
    # Get the fully qualified name of the class
    # @return [String] the full name of the class, e.g. com.example.projects.Circle
    def fullname
      "#{@package.fullname}.#{@name}"
    end
    
    # #to_s is #fullname
    alias to_s fullname
  
  
  
  
    # Compile the program
    # Raises a CompilerException if there was a problem compiling
    # @return [JavaHead::Class] this class object
    def compile(*args)
      remove_class if compiled?
      command = 'javac '
      args.each do |arg|
        arg = arg.to_s
        raise CompilerException, "Invalid compiling argument #{arg}" unless arg.match ARGFORMAT
      end
      command << args.join(' ')
      command << ' '
      command << @path.to_s
      output = `#{command}`
      raise CompilerException, "Class #{fullname} could not compile" unless compiled?
      self
    end
  
    # Remove the existing compiled class
    #
    # @return [JavaHead::Class, Boolean] this class object or false if not successful
    def remove_class
      Dir.chdir(@package.path) do
        Pathname.glob("#{@name}$*.class") do |pathname|
          pathname.unlink
        end
        Pathname.new("#{@name}.class").unlink
      end
      self
      
    # the file doesn't exist or there was a problem loading it
    rescue Errno::ENOENT
      return false
    end
  
    # Test to see if compilation works, args are passed to the compile method
    #
    # @param [Array] args the arguments to be passed to the #compile method
    # @return [JavaHead::Class,NilClass] this class object or nil if the compilation failed
    def test(*args)
      compile(*args)
      remove_class
      self
    rescue Exception => e
      puts "Exception of type #{e.class} while compiling #{fullname}: #{e}"
      nil
    end
  
    # Integrated compile, run, remove_class
    # This method assumes to some extent that
    # compilation will succeed, so although this may fail,
    # its arguments are passed to the exec method
    #
    # @param [Array] args the arguments to be passed to the #exec method
    # @return [String] the output created by the Java program
    def run(*args)
      compile # this is a simple list of things for the interpreter to do
      output = exec *args
      remove_class
      output # return output
    end
  
    # Check if the class is compiled?
    #
    # @return [Boolean] whether or not the class compiled
    def compiled?
      @path.dirname.join("#{@name}.class").exist?
    end
  
    # Take given command line arguments, check them for validity, add them to a java command and run the command to execute the class
    #
    # @param [Array] args the command-line arguments to be passed to the Java program
    # @return [String] the output of the program execution
    def exec(*args)
      raise RunnerException, "Class #{fullname} cannot be run because it is not compiled" unless compiled?
      command = "java #{fullname}"
      args.each do |arg|
        arg = arg.to_s
        raise RunnerException, "Invalid command-line argument: #{arg}" unless arg.match ARGFORMAT
        command << ' '
        command << arg
      end
      `#{command}`
    end
  
    # Inspect incorporates meaningful data like name, location and whether class is compiled
    # @return [String] useful data about the current object
    def inspect
      "[Java Class, name: #{fullname}, path: #{@path}, #{ compiled? ? 'Compiled' : 'Not Compiled'}]"
    end
    
    # The format for command-line arguments
    ARGFORMAT = /^[\-a-zA-Z@][a-zA-Z0-9\-:="'@]*$/.freeze
    # The format for classnames, e.g. com.example.projects.Shape
    FORMAT = /^([a-z_][a-z0-9_]*\.)*[A-Z][a-z0-9_]*$/.freeze
    
    
  end
  
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
  end
  
  # An array of Pathnames representing the CLASSPATH environment variable
  # Defaults to the current values of the $CLASSPATH environment variable
  CLASSPATH = [Pathname.new('.')]
  
  if ENV['CLASSPATH'] # if there is a CLASSPATH environment variable, let's use it.
    ENV['CLASSPATH'].split(':').each do |string| # Add all class path env variables to the CLASSPATH as Pathnames
      CLASSPATH.push( Pathname.new(string) )
    end
  end
  
  CLASSPATH.uniq!
  
  # General Java::Class exception
  class ClassException < StandardError
  end
  # General Java::Package exception
  class PackageException < StandardError
  end
  
  # Represents exceptions while compiling
  class CompilerException < StandardError
  end
  
  
  # Represents exceptions while running
  class RunnerException < StandardError
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
