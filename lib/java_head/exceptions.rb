 module JavaHead::Exceptions

  # a JavaHead exception
  class JavaHeadException < StandardError
  end
  # General JavaHead::ClassException
  class ClassException < JavaHeadException
  end
  # General JavaHead::Package exception
  class PackageException < JavaHeadException
  end
  
  # Represents exceptions while compiling
  class CompilerException < ClassException
  end
  
  
  # Represents exceptions while running
  class RunnerException < ClassException
  end
end
