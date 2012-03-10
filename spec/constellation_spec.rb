# encoding: utf-8

require "spec_helper"

describe Constellation do

  let(:load_from_gems) { false }
  let(:path) { 'config/chomper.yml' }
  let(:home) { ENV['HOME'] }

  let(:config_class) do
    Class.new.tap do |c|
      c.acts_as_constellation
      c.env_params = { foo: 'MY_FOO', bar: 'MY_BAR' }
      c.config_file = path
      c.load_from_gems = load_from_gems
    end
  end

  def write(base_dir, content)
    full_path = File.join(base_dir, path)
    FileUtils.mkdir_p File.dirname(full_path)
    File.open(full_path, 'w') { |f| f << content }
  end

  describe 'a configuration object' do
    subject { config_class.new(foo: 'FOO') }

    it('responds to properties') { subject.should respond_to(:foo) }
    it('returns properties when called directly') { subject.foo.should == 'FOO' }
    it('exposes properties via []') { subject[:foo].should == 'FOO' }
    it('treats Symbol and String keys indifferently') { subject[:foo].should == subject['foo'] }
  end

  describe 'configuration sources' do
    subject    { config_class.new(foo: 'paramfoo') }

    let(:cwd)  { '/somewhere' }

    before do
      ENV['MY_FOO'] = 'envfoo'
      ENV['MY_BAR'] = 'envbar'

      write(cwd, YAML.dump({ 'foo' => 'dotfoo', 'bar' => 'dotbar', 'baz' => 'dotbaz' }))
      write(home, YAML.dump({ 'foo' => 'homefoo', 'bar' => 'homebar', 'baz' => 'homebaz', 'qux' => 'homequx' }))
    end

    after { ENV.delete('MY_FOO'); ENV.delete('MY_BAR') }

    it('prefers passed parameters') { Dir.chdir(cwd) { subject.foo.should == 'paramfoo' } }
    it('falls back on ENV')         { Dir.chdir(cwd) { subject.bar.should == 'envbar' } }
    it('falls back on CWD/path')    { Dir.chdir(cwd) { subject.baz.should == 'dotbaz' } }
    it('falls back on ~/path')      { Dir.chdir(cwd) { subject.qux.should == 'homequx' } }
  end

  describe 'load_from_gems' do
    subject    { config_class.new }

    let(:gem_dir) { '/gems/some_gem' }
    let(:gems) {
      { 'some_gem' => stub('Configuration', gem_dir: gem_dir) }
    }

    before do
      Gem.stubs(:loaded_specs).returns(gems)
      write(home, YAML.dump({ 'foo' => 'homefoo' }))
      write(gem_dir, YAML.dump({ 'foo' => 'gemfoo', 'bar' => 'gembar' }))
    end

    context('with load_from_gems off') do
      it("doesn't load from gems") { subject.should_not respond_to(:bar) }
    end

    context('with load_from_gems on') do
      let(:load_from_gems) { true }
      it('prefers ~/path')            { subject.foo.should == 'homefoo' }
      it("falls back on [gems]/path") { subject.bar.should == 'gembar' }
    end
  end

  describe 'file parsing' do
    subject    { config_class.new }

    context 'with a .yml file' do
      let(:path) { 'config.yml' }
      before { write(home, YAML.dump({ 'foo' => 'yamlfoo' })) }
      it('parses as YAML') { subject.foo.should == 'yamlfoo' }
    end

    context 'with a .json file' do
      let(:path) { 'config.json' }
      before { write(home, MultiJson.encode({ 'foo' => 'jsonfoo' })) }
      it('parses as JSON') { subject.foo.should == 'jsonfoo' }
    end

    context 'with an unknown extension' do
      let(:path) { 'config.xqx' }
      before { write(home, "foo: xqxfoo") }
      it('throws an exception') do
        expect { subject }.to raise_error(Constellation::ParseError)
      end
    end

    context 'with a custom parser' do
      let(:path) { 'config.col' }
      let(:subject) do
        config_class.class_eval do
          define_method :parse_config_file do |contents|
            contents.split("\n").inject({}) do |sum, line|
              k, v = line.split(':')
              sum[k] = v
              sum
            end
          end
        end
        config_class.new
      end

      before { write(home, "foo:colonfoo") }

      it('parses with the given parse method') { subject.foo.should == 'colonfoo' }
    end
  end

  describe '#to_hash' do
    subject { config_class.new(foo: 'FOO') }

    it 'returns a Hash containing the settings' do
      subject.to_hash['foo'].should == 'FOO'
    end

    it 'returns a defensive copy' do
      subject.to_hash['foo'] = 'BAR'
      subject.foo.should == 'FOO'
    end
  end

  describe 'enumerable methods' do
    subject { config_class.new(foo: 'FOO') }

    it 'enumerates over the settings' do
      result = []
      subject.each { |k,v| result << [k,v] }
      result.should == [ ['foo', 'FOO'] ]
    end

    it('is an Enumerable') { subject.should be_kind_of(Enumerable) }
  end
end
