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

    it "returns 9070 subtags" do
      expect(Registry.parse.subtags.count).to eq 9070
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

  let(:armenian_family) do
    Subtag.new(
      type: "language",
      code: "hyx",
      description: "Armenian (family)",
      added: Date.new(2007, 7, 29),
      scope: "collection",
    )
  end

  let(:konkani) do
    Subtag.new(
      type: "language",
      code: "kok",
      description: "Konkani (macrolanguage)",
      added: Date.new(2005, 10, 16),
      suppress_script: "Deva",
      scope: "macrolanguage",
    )
  end

  it "has a type" do
    expect(subtag.type).to eq 'language'
  end

  it "has a code" do
    expect(subtag.code).to eq 'hrx'
  end

  it "has descriptions" do
    expect(subtag.descriptions).to eq ['Hunsrik']
  end

  it "has an added date" do
    expect(subtag.added).to eq Date.new(2009, 7, 29)
  end

  it "has a suppress-script" do
    expect(konkani.suppress_script).to eq 'Deva'
  end

  it "has a scope" do
    expect(armenian_family.scope).to eq 'collection'
  end

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

  describe '#add_description' do
    it "adds a description" do
      expect do
        subtag.add_description "Afar"
      end.to change(subtag.descriptions, :count).by(1)
    end
  end
end
