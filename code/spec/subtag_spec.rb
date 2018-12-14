require 'spec_helper'

describe Registry do
  let(:registry) { Registry.new }

  it "has a file date" do
    expect(Registry.parse.file_date).to eq Date.new(2018, 11, 30)
  end

  it "has subtags" do
    expect(registry.subtags).to be_an Array
  end

  describe '.parse' do
    it "returns a registry" do
      expect(Registry.parse).to be_a Registry
    end

    it "returns subtags" do
      expect(Registry.parse.subtags.map(&:class).uniq).to eq [Subtag]
    end
  end

  describe '#add_subtag' do
    it "adds a subtag to the registry" do
      expect do
        registry.add_subtag Subtag.new(code: 'hi', descriptions: ["Hindi"])
      end.to change(registry.subtags, :count).by(1)
    end
  end
end

describe Subtag do
  let(:subtag) do
    Subtag.new(
      type: "language",
      code: "hrx",
      descriptions: ["Hunsrik"],
      added: Date.new(2009, 7, 29),
    )
  end

  it "has a type"
  it "has a code"
  it "has descriptions"
  it "has an added date"
  it "has a suppress-script"
  it "has a scope"

  describe '.new' do
    it "returns a Subtag" do
      expect(Subtag.new).to be_a Subtag
    end

    it "takes an optional parameter hash" do
      expect do
        subtag = Subtag.new(code: "hrz", descriptions: "Harzani")
      end.not_to raise_exception
    end
  end
end
