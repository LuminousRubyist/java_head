# JavaHead

JavaHead is designed to run Java classes easily with familiar Ruby syntax. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'java_head'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install java_head

## Usage

Use the two primary JavaHead classes, Package and Class, to represent Java packages and classes, respectively. Here is some basic usage:

```ruby
require 'java_head'

# JavaHead::CLASSPATH is an array of Pathnames that represent where JavaHead will search for your classes. Its initial value is created based on the CLASSPATH environment variable
# You can also change your CLASSPATH like so:
JavaHead::CLASSPATH.push(Pathname.new('/my/java/classpath'))

# Get a package, this will load the package corresponding to /my/java/classpath/com/example/foo
package = JavaHead > 'com.example.foo'


subpackage = package > 'bar'    # Pull up a subpackage
subpackage.compile              # invoke javac to compile all files in the ppackage
subpackage.remove_class         # remove .class files

jclass = subpackage > 'MyClass' # Also JavaHead > 'com.example.foo.bar.MyClass' or 'com.example.foo.bar.MyClass'.java
jclass.package == subpackage    # => true
jclass.compile                  # Compile the class, this returns the JavaHead::Class object
jclass.exec                     # Execute the compiled class, this returns the output of the execution
jclass.remove_class             # Remove the .class file
jclass.run                      # Do the same thing with only one method, this returns the same as #exec()
jclass.run('Hello','World')     # You can also pass command-line arguments to your Java programs




```

## Contributing

1. Fork it ( https://github.com/AndrewTLee/java_head/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
