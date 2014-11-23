
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
    def fullname
      return @name unless @superpackage
      "#{@superpackage.fullname}.#{@name}"
    end
    
    # to_s returns fullname
    alias to_s fullname
    
    # print useful fully-qualified name and path of class
    def inspect
      "[Java Package, name: #{fullname}, path: #{path}]"
    end
    
    # return a subpackage of the current package
    def subpackage(name)
      self.class.get("#{fullname}.#{name}")
    end
    
    # return a class within the current package
    def class(name=nil)
      return super() if name.eql? nil
      Class.new("#{fullname}.#{name}")
    end
    
    # return all classes in the current package
    def classes
      Dir.chdir(@path) do
        Dir.glob('*.java').map! do |filename|
          self.class( filename.match(/^([A-Z][A-Za-z0-9]*)\.java$/)[1] )
        end
      end
    end
    
    # compile all classes in the package
    def compile
      classes.each { |c| c.compile }
      self
    end
    
    # call #remove_class on all class files of the package
    def remove_class
      classes.each { |c| c.remove_class }
      self
    end
    
    
    
    # returns #class(name) or #subpackage(name) depending on the format of name
    def member(name)
      if name.match Class::FORMAT
        self.class(name)
      else
        subpackage(name)
      end
      
    end
    
    # > is a handy operator alias for member
    alias > member
    
    
    
    
    FORMAT = /^[a-z0-9.]+$/.freeze
    @@stored = Hash.new
    
    
    class << self
      private :new
      
      # Check the @@stored cache, then create a new object if the one with name doesn't exist
      def get(name)
        sym = name.intern
        return @@stored[sym] if @@stored[sym]
        package = new(name)
        @@stored[sym] = package
        package
      end
      
    end
    
  end
  
  # Represent Java Classes
  class Class
    def initialize(name)
      raise ClassException, "Invalid class name #{name}" unless name.match FORMAT
      
      names = name.split('.')
      @name = names.pop.freeze
      @package = Package.get(names.join('.'))
      @path = @package.path.join("#{@name}.java")
      
      raise ClassException, "Location not found for class #{name}" unless @path.exist? and @path.file?
    end
    
    attr_reader :name, :package, :path
    
    # Fully qualified name of the class
    def fullname
      "#{@package.fullname}.#{@name}"
    end
    
    # #to_s is #fullname
    alias to_s fullname
  
  
  
  
    # Compile the program
    # Raises a CompilerException if there was a problem compiling
    # returns self
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
      system command
      raise CompilerException, "Class #{fullname} could not compile" unless compiled?
      self
    end
  
    # Remove the existing compiled class, returns self or false if unsuccessful
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
    def run(*args)
      compile # this is a simple list of things for the interpreter to do
      exec *args
      remove_class
      self # return self
    end
  
    # Is the class compiled?
    def compiled?
      @path.dirname.join("#{@name}.class").exist?
    end
  
    # Take given command line arguments, check them for validity, add them to a command and run the command
    def exec(*args)
      raise RunnerException, "Class #{fullname} cannot be run because it is not compiled" unless compiled?
      command = "java #{fullname}"
      args.each do |arg|
        arg = arg.to_s
        raise RunnerException, "Invalid command-line argument: #{arg}" unless arg.match ARGFORMAT
        command << ' '
        command << arg
      end
      system command
      self
    end
  
    # Inspect incorporates meaningful data like name, location and whether class is compiled
    def inspect
      "[Java Class, name: #{fullname}, path: #{@path}, #{ compiled? ? 'Compiled' : 'Not Compiled'}]"
    end
    
    ARGFORMAT = /^\-?[A-Za-z0-9]*$/.freeze
    FORMAT = /^([a-z0-9.]+)?[A-Z][A-Za-z0-9]*$/.freeze
    
    # Represents exceptions while compiling
    class CompilerException < StandardError
    end
    
    
    # Represents exceptions while running
    class RunnerException < StandardError
    end
  end
  
  # Methods in the eigenclass of Java
  class << self
    # Find a package using Package.get
    def package(name)
      Package.get(name)
    end
    
    # Returns the class with no arguments
    # Returns a new class with the given name if an argument is passed
    def class(name = nil)
      return super() if name.eql? nil
      Class.new(name)
    end
    
    # Creates either a class or a package
    # depending on the format of the given string
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
  # Defaults to . and sources from classpath.txt config file if it exists in the same
  # directory as __FILE__
  CLASSPATH = ['.']
  # initialize CLASSPATH from config file if present
  Dir.chdir(__dir__) do
    if File.exist? 'classpath.txt'
      File.open('classpath.txt','r') do |file|
        file.each_line do |string|
          CLASSPATH.push(string.chomp)
        end
      end
    end
  end
  CLASSPATH.map! { |string| Pathname.new(string) }
  
  # General Java::Class exception
  class ClassException < StandardError
  end
  # General Java::Package exception
  class PackageException < StandardError
  end
  
end

class String
  # This method allows
  # Java::Package.get('com.example.shapes')
  # to be written:
  # 'com.example.shapes'.java
  # and
  # Java::Class.new('com.example.shapes.Circle')
  # to be written as
  # 'com.example.shapes.Circle'.java
  def java
    JavaHead.member self
  end
end