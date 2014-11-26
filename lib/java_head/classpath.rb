module JavaHead
  # An array of Pathnames representing the CLASSPATH environment variable
  # Defaults to the current values of the $CLASSPATH environment variable
  CLASSPATH = [Pathname.new('.')]
  
  if ENV['CLASSPATH'] # if there is a CLASSPATH environment variable, let's use it.
    ENV['CLASSPATH'].split(':').each do |string| # Add all class path env variables to the CLASSPATH as Pathnames
      CLASSPATH.push( Pathname.new(string) )
    end
  end
  
  CLASSPATH.uniq!
end