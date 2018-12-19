require 'date'
require 'byebug'

class Registry
  attr_accessor :file_date, :subtags
  @@registry = nil

  def initialize
    @subtags = []
  end

  def self.parse
    unless @@registry
      @@registry = new # TODO Spec out that we cache
      @@missed_types = []
      subtag = Subtag.new
      stack = nil
      File.read(File.expand_path('../../language-subtag-registry', __dir__)).each_line do |line|
        if line =~ /^File-Date: (.*)$/ # TODO Use named parameters all around?
          @@registry.file_date = Date.parse($1)
        elsif line.strip == '%%' # TODO strip_right?
          @@registry.add_subtag subtag unless subtag.empty?
          subtag = Subtag.new
        elsif line =~ /^  (.*)$/
          stack[stack.keys.first] = sprintf('%s %s', stack.values.first.strip, $1)
        elsif line =~ /^Type: (.*)$/
          flush_stack subtag, stack
          stack = { type: $1 }
        elsif line =~ /^Subtag: (.*)$/
          flush_stack subtag, stack
          stack = { code: $1 }
        elsif line =~ /^Description: (.*)$/
          flush_stack subtag, stack
          stack = { description: $1 }
        elsif line =~ /^Added: (.*)$/
          flush_stack subtag, stack
          stack = { added: Date.parse($1) }
        elsif line =~ /^Suppress-Script: (.*)$/
          flush_stack subtag, stack
          stack = { suppress_script: $1 }
        elsif line =~ /^Scope: (.*)$/
          flush_stack subtag, stack
          stack = { scope: $1 }
        elsif line =~ /^Macrolanguage: (.*)$/
          flush_stack subtag, stack
          stack = { macrolanguage: $1 } # TODO point to the actual entry!
        elsif line =~ /^Comments: (.*)$/
          flush_stack subtag, stack
          stack = { comments: $1 }
        elsif line =~ /^Deprecated: (.*)$/
          flush_stack subtag, stack
          stack = { deprecated: $1 }
        elsif line =~ /^Preferred-Value: (.*)$/
          flush_stack subtag, stack
          stack = { preferred_value: $1 }
        elsif line =~ /^Tag: (.*)$/
          flush_stack subtag, stack
          stack = { tag: $1 }
        elsif line =~ /^Prefix: (.*)$/
          flush_stack subtag, stack
          stack = { prefix: $1 }
        else
          # raise "Error: line type unknown: #{line}; subtag = #{subtag.code}" # FIXME temp
          # type = line.gsub(/^(.*?):.*/, $1).downcase
          @@missed_types << line
        end
      end

      raise "Missed types: #{@@missed_types.uniq}" if @@missed_types.count > 0
      flush_stack subtag, stack unless stack.empty?
      @@registry.add_subtag subtag unless subtag.empty?
    end

    @@registry
  end

  def add_subtag(subtag) # TODO << ?
    @subtags << subtag
  end

  def self.flush_stack subtag, stack # TODO Spec out!
    return unless stack

    # puts stack[:code] if stack[:code]
    # [:type, :code, :added, :suppress_script, :scope, :macrolanguage, :comments, :deprecated, :preferred_value, :tag, :prefix].each do |key|
    stack.each do |key, value|
      next if key == :description
      subtag.send sprintf('%s=', key), stack.delete(key)
      return if stack.empty?
    end
    description = stack.delete(:description)
    subtag.add_description description if description
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
    SIMPLE_VALUES.all? { |key| !self.send(key) } && (!@descriptions || @descriptions && @descriptions.count == 0)
  end
end
