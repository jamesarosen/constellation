## Constellation

Constellation is a powerful configuration system. It's great for
API client libraries and applications and anywhere else you need to
let your users set some configuration parameters.

## Usage

### Ruby Parameters

Start by creating a class and calling `Constellation.enhance`:

```ruby
class MyConfiguration
  Constellation.enhance self
end
```

With just this, you have a basic Hash configuration. The only way to set
properties is to pass them in Ruby:

```ruby
config = MyConfiguration.new(:foo => 'bar')
...
config.foo # => "bar"
```

### `ENV`

To add support for `ENV` hash configuration, set `env_params`:

```ruby
class MyConfiguration
  self.env_params = { :foo => 'MY_FOO' }
end

...
ENV['MY_FOO'] = 'bar'
...
config = MyConfiguration.new
config.foo # => "bar"
```

### Configuration Files

To add support for config files, set `config_file` to a path. The Constellation
will look up a config file in that location relative to two places ("base paths"):

 * the current working directory (`Dir.pwd`)
 * the user's home directory (`ENV['HOME']`)

```ruby
class MyConfiguration
  self.config_file = 'my/config.yml'
end
```

If `./my/config.yml` contains the following

```yml
--- 
foo: bar
```

then `MyConfiguration.new.foo` will return `"bar"`.

### From Gems

If you set `config_file` to a path *and* set `load_from_gems` to `true`, then
Constellation will add all of the loaded gem directories to the list of base paths.

```ruby
class MyConfiguration
  self.config_file = 'my/config.yml'
  self.load_from_gems = true
end
```

## Order of Precedence

Constellation will load parameters in the order listed above. Given

```ruby
class MyConfiguration
  self.env_params = { :foo => 'MY_FOO' }
  self.config_file = 'my/config.yml'
  self.load_from_gems = true
end
```

Constellation will first look in a Hash passed in, then in `ENV`, then in
`./my/config.yml`, then in `~/my/config.yml`, then in `GEM_PATH/my/config.yml` for
each loaded gem.

## File Parsers

Constellation will do the right thing if `config_file` ends with `.yml`, `.yaml`, or
`.json`. If it's a different format, you'll have to tell Constellation how to parse it
by redefining `parse_config_file`:

```ruby
class MyConfiguration
  self.config_file = '.myrc'

  def parse_config_file(contents)
    result = {}
    contents.split("\n").each do |line|
      k, v = line.split(/:\s*/)
      result[k] = v
    end
    result
  end
end
```
