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
        puts 1
        registry.file_date = Date.parse($1)
      elsif line =~ /%%/
        puts 2
        registry.add_subtag subtag
        puts registry.subtags.count
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
  def initialize(params = { })
    @code = params[:code]
    @type = params[:type]
    @scope = params[:scope]
    @added = params[:added]
    @suppress_script = params[:suppress_script]
    @descriptions = params[:descrptions]
  end
end
