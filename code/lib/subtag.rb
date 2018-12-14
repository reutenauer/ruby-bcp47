require 'date'

class Registry
  attr_accessor :file_date, :subtags

  def initialize
    @subtags = []
  end

  def self.parse
    registry = new
    subtag = Subtag.new
    File.read(File.expand_path('../../language-subtag-registry', __dir__)).each_line do |line|
      if line =~ /^File-Date: (.*)$/
        registry.file_date = Date.parse($1)
      elsif line =~ /%%/
        registry.add_subtag subtag
        subtag = Subtag.new
      end
    end

    registry
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
    @descriptions = params[:descriptions]
  end
end
