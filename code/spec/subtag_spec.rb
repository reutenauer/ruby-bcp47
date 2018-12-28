require 'spec_helper'

describe String do
  describe '#strip_right' do
    it "strips to the right" do
      expect(" foo   ".strip_right).to eq " foo"
    end
  end
end

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

  describe '.file_date' do
    it "returns the registry file’s date" do
      expect(Registry.file_date).to eq Date.new(2018, 11, 30)
    end

    it "calls .subtags first" do
      expect(Registry).to receive :subtags
      Registry.file_date
    end
  end

  it "has subtags" do
    expect(Registry.subtags).to be_an Array
  end

  describe '.subtags' do
    it "returns the subtags" do
      expect(Registry.subtags.map(&:class).uniq).to eq [Subtag]
    end

    it "returns 9070 subtags" do
      expect(Registry.subtags.count).to eq 9070
    end

    it "returns actual subtags" do
      expect(Registry.subtags.map(&:code).select { |code| code == 'Hant' }).to eq ['Hant']
    end

    it "wraps lines" do
      allow(Net::HTTP).to receive(:get).and_return interlingua
      Registry.class_variable_set :@@subtags, nil
      subtags = Registry.subtags
      expect(subtags.first.descriptions.first).to eq 'Interlingua (International Auxiliary Language Association)'
      Registry.class_variable_set :@@subtags, nil
    end

    it "caches the result" do
      Registry.subtags
      expect(Registry.class_variable_get(:@@subtags).count).to eq 9070
    end

    it "only opens the registry file once" do
      Registry.class_variable_set :@@subtags, nil
      expect(Net::HTTP).to receive(:get).exactly(:once).and_return("File-Date: 2018-12-28\n%%\nSubtag: aa\nDescription: Afar")
      Registry.subtags
      Registry.subtags
      Registry.class_variable_set :@@subtags, nil
    end
  end

  describe "sanity checks" do
    it "finds the subtag CS" do
      serbia_and_montenegro = Registry.subtags.select { |subtag| subtag.code == "CS" }.first
      expect(serbia_and_montenegro.type).to eq "region"
      expect(serbia_and_montenegro.descriptions).to eq ["Serbia and Montenegro"]
    end

    it "finds the subtag cs" do
      czech = Registry.subtags.select { |subtag| subtag.code == "cs" }.first
      expect(czech.type).to eq "language"
      expect(czech.descriptions).to eq ["Czech"]
    end

    it "finds the subtag Cyrs" do
      cyrillic_ocs = Registry.subtags.select { |subtag| subtag.code == "Cyrs" }.first
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

  describe '#flush_stack' do
    it "overwrites simple fields" do
      subtag = Subtag.new
      stack = ['code', "aa"]
      subtag.flush_stack stack
      expect(subtag.code).to eq "aa"
    end

    it "adds to cumulative fields" do
      subtag = Subtag.new
      stack = ['description', 'The AA Language']
      subtag.flush_stack stack
      expect(subtag.descriptions).to eq ['The AA Language']
    end
  end
end
