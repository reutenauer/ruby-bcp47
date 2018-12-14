require 'date'

class Registry
  attr_accessor :file_date, :subtags
  @@registry = nil

  def initialize
    @subtags = []
  end

  def self.parse
    unless @@registry
      registry = new
      subtag = Subtag.new
      File.read(File.expand_path('../../language-subtag-registry', __dir__)).each_line do |line|
        if line =~ /^File-Date: (.*)$/
          registry.file_date = Date.parse($1)
        elsif line.strip == '%%'
          registry.add_subtag subtag
          subtag = Subtag.new
        elsif line =~ /^Type: (.*)$/
          subtag.type = $1
        elsif line =~ /^Subtag: (.*)$/
          subtag.code = $1
        elsif line =~ /^Description: (.*)$/
          subtag.add_description $1
        elsif line =~ /^Added: (.*)$/
          subtag.added = Date.parse $1
        elsif line =~ /^Suppress-Script: (.*)$/
          subtag.suppress_script = $1
        elsif line =~ /^Scope: (.*)$/
          subtag.scope = $1
        else
          raise "Error: line type unknown: #{line}"
        end
      end
    end

    @@registry
  end

  def add_subtag(subtag)
    @subtags << subtag
  end
end

class Subtag
  attr_accessor :type, :code, :descriptions, :added, :suppress_script, :scope

  def initialize(params = { })
    @code = params[:code]
    @type = params[:type]
    @scope = params[:scope]
    @added = params[:added]
    @suppress_script = params[:suppress_script]
    @descriptions = params[:descriptions] || []
  end

  def add_description description
    @descriptions << description
  end
end
