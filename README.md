# Wut

`Wut` is a faster, lazier, way to do puts debugging. With 3 characters, you can get a 
printout of your variable values. Great for debugging, or feeding into an LLM.

```ruby
w.tf
```

## Features

- **Dynamic Variable Inspection**: View locals, instance variables, globals, class variables, and `let` variables with simple commands.
- **Customizable Output**: Automatically excludes ignored variables defined in an ignore list.
- **Colorized Output**: Enhanced readability with color-coded debug information.

## Installation

Add `Wut` to your Gemfile:

```ruby
bundle add wut
```

Or install it manually:

```sh
gem install wut
```

## Usage

### Commands

`Wut` enhances the `binding` object, allowing you to inspect variables with concise syntax:
It also gives you a short alias--w for quick debugging.

- `w.l` - Print **l**ocal variables.
- `w.i` - Print **i**nstance variables.
- `w.c` - Print **c**lass variables.
- `w.g` - Print **g**lobal variables.
- `w.tf` - Print **t**he **f**ull set of variables--locals, instance, class and lets.
- `w.tf?` - Print **t**he **f**ull set of variables, plus globals too.

If you opt not to create the alias for binding, you can get the same methods from
binding. 


```ruby
require 'wut'

class Example
  @@class_var = "class variable"

  def initialize
    @instance_var = "instance variable"
  end

  def debug_example
    local_var = "local variable"
    w.tf?  # Print all variables
    w.l  # Print only locals
  end
end

Example.new.debug_example
```

Output:

```
From: example.rb:13

Locals:
  local_var: "local variable"

Instances:
  @instance_var: "instance variable"

Class Vars:
  @@class_var: "class variable"

Globals:
```

### Ignore List

Customize the variables excluded from output by adding them to the ignore list:

```ruby
Wut.ignore_list << :@ignored_var
```

### Integration

Automatically enable `Wut` by requiring it:

```ruby
require 'wut'
```

## Development

After cloning the repository, set up the environment:

```sh
bin/setup
```

Run the tests:

```sh
bundle exec rspec
```

## Contributing

Contributions are welcome! Please submit bug reports and pull requests at [GitHub](https://github.com/ericbeland/wut).

## License

This gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

