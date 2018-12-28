require 'date'
require 'byebug'

class String
  def strip_right
    gsub /\s*$/, ''
  end
end

class Registry
  attr_accessor :file_date, :subtags
  @@registry = nil

  def initialize
    @subtags = []
  end

  def self.parse
    unless @@registry
      @@registry = new
      @@missed_types = []
      subtag = Subtag.new
      stack = nil
      File.read(File.expand_path('../../language-subtag-registry', __dir__)).each_line do |line|
        # byebug
        if line =~ /^File-Date: (.*)$/ # TODO Use named parameters all around?
          @@registry.file_date = Date.parse($1)
        elsif line.strip_right == '%%'
          @@registry << subtag unless subtag.empty?
          subtag = Subtag.new
        elsif line =~ /^  (.*)$/
          stack = [stack.first, sprintf('%s %s', stack.last.strip, $1)]
        elsif line =~ /^([A-Z][a-zA-Z-]+): (.*)$/
          subtag.flush_stack stack
          value = $2
          key = $1.gsub(/Subtag|Tag/, 'code').downcase.gsub('-', '_')
          stack = [key, value]
        else
          # type = line.gsub(/^(.*?):.*/, $1).downcase
          @@missed_types << line
        end
      end

      raise "Missed types: #{@@missed_types.uniq}" if @@missed_types.count > 0
      subtag.flush_stack stack unless stack.empty?
      @@registry << subtag unless subtag.empty?
    end

    @@registry
  end

  def <<(subtag)
    @subtags << subtag
  end
end

class Subtag
  SIMPLE_VALUES = [:type, :code, :added, :suppress_script, :scope, :macrolanguage, :comments, :deprecated, :preferred_value, :tag, :prefix]
  SIMPLE_VALUES.each { |key| attr_accessor key }
  attr_accessor :descriptions

  def initialize(params = { })
    SIMPLE_VALUES.each do |key|
      self.send sprintf('%s=', key), params[key]
    end
    @descriptions = params[:descriptions] || []
  end

  def add_description description
    @descriptions << description
  end

  def empty?
    SIMPLE_VALUES.all? { |key| !self.send(key) } and !@descriptions || @descriptions && @descriptions.count == 0
  end

  def flush_stack stack
    return unless stack

    # byebug if stack.keys.first == 'description'
    if stack.first == 'description'
      add_description stack.last
    else
      # byebug if stack == {code: 'aa'}
      send sprintf('%s=', stack.first), stack.last
    end
  end
end
