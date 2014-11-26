module JavaHead
  
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
end