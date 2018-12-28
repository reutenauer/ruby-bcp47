require 'date'
require 'byebug'
require 'net/http'
require 'uri'

class NilKey < StandardError; end

class String
  def strip_right
    gsub /\s*$/, ''
  end
end

class Hash
  def <= key, value
    raise NilKey unless key

    existing = self[key]
    if existing
      if existing.is_a? Enumerable
        self[key] << value
      else
        self[key] = [existing, value]
      end
    else
      self[key] = value
    end
  end
end

module BCP47
  class Registry
    def self.file_date
      subtags
      @@file_date
    end

    def self.subtags
      @@subtags ||= Hash.new.tap do |subtags|
        @@missed_types = []
        subtag = Subtag.new
        stack = nil
        Net::HTTP.get(URI('https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry')).each_line do |line|
          if line =~ /^File-Date: (.*)$/ # TODO Use named parameters all around?
            @@file_date = Date.parse($1)
          elsif line.strip_right == '%%'
            unless subtag.empty?
              subtags.<= subtag.code, subtag
            end
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
        subtags.<= subtag.code, subtag unless subtag.empty?
      end
    end

    def self.[] code
      subtags[code]
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
      SIMPLE_VALUES.none? { |key| send(key) } and !@descriptions || @descriptions && @descriptions.count == 0
    end

    def flush_stack stack
      return unless stack

      if stack.first == 'description'
        add_description stack.last
      else
        send sprintf('%s=', stack.first), stack.last
      end
    end
  end
end