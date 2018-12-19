require 'spec_helper'

describe Registry do
  let(:registry) { Registry.new }
  let(:interlingua) do
    <<-EOIA
Type: language
Subtag: ia
Description: Interlingua (International Auxiliary Language
  Association)
  EOIA
  end

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

    it "returns actual subtags" do
      expect(Registry.parse.subtags.map(&:code).select { |code| code == 'Hant' }).to eq ['Hant']
    end

    it "wraps lines" do
      allow(File).to receive(:read).and_return interlingua
      Registry.class_variable_set :@@registry, nil # FIXME!!
      registry = Registry.parse
      expect(registry.subtags.first.descriptions.first).to eq 'Interlingua (International Auxiliary Language Association)'
    end

    it "fixes its face afterwards" do # FIXME!!!
      Registry.class_variable_set :@@registry, nil
    end
  end

  describe '#add_subtag' do
    it "adds a subtag to the registry" do
      expect do
        registry.add_subtag Subtag.new(code: 'hi', descriptions: ["Hindi"])
      end.to change(registry.subtags, :count).by(1)
    end
  end

  describe '.flush_stack' do
    it "works" do
      subtag = Subtag.new
      stack = { code: "aa" }
      Registry.flush_stack subtag, stack
      expect(subtag.code).to eq "aa"
    end
  end

  describe "sanity checks" do
    it "finds the subtag CS" do
      serbia_and_montenegro = Registry.parse.subtags.select { |subtag| subtag.code == "CS" }.first
      byebug
      expect(serbia_and_montenegro.type).to eq "region"
      expect(serbia_and_montenegro.descriptions).to eq ["Serbia and Montenegro"]
    end

    it "finds the subtag cs" do
      czech = Registry.parse.subtags.select { |subtag| subtag.code == "cs" }.first
      expect(czech.type).to eq "language"
      expect(czech.descriptions).to eq ["Czech"]
    end

    it "finds the subtag Cyrs" do
      cyrillic_ocs = Registry.parse.subtags.select { |subtag| subtag.code == "Cyrs" }.first
      expect(cyrillic_ocs.type).to eq "script"
      expect(cyrillic_ocs.descriptions).to eq ["Cyrillic (Old Church Slavonic variant)"]
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

  let(:bosnian) { Subtag.new(code: 'bs', macrolanguage: 'sh') }
  let(:western_armenian) { Subtag.new(code: 'hyw', comments: 'see also hy') }

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

  it "may have a macrolanguage" do
    expect(bosnian.macrolanguage).to eq 'sh' # TODO Make it an actual subtag later
  end

  it "may have comments" do
    expect(western_armenian.comments).to eq 'see also hy'
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

    describe '#empty?' do
      it "returns true if subtag is empty" do
        expect(Subtag.new.empty?).to be_truthy
      end
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
