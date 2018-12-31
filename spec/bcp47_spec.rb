require 'spec_helper'

include BCP47

describe String do
  describe '#strip_right' do
    it "strips to the right" do
      expect(" foo   ".strip_right).to eq " foo"
    end
  end

  describe '#capitalize' do
    it "capitalises" do
      expect('hans'.capitalize).to eq "Hans"
    end
  end
end

describe Hash do
  describe '#<=' do
    it "inserts or append" do
      empty = Hash.new
      empty.<= :a, 1
      expect(empty).to be == { a: 1 }
    end

    it "appends to a scalar entry" do
      scalar = { a: 1 }
      scalar.<= :a, 2
      expect(scalar).to eq(a: [1, 2])
    end

    it "appends to a composite entry" do
      composite = { a: [1, 2] }
      composite.<= :a, 3
      expect(composite).to be == { a: [1, 2, 3] }
    end

    it "raises an exception if key is nil" do
      expect { Hash.new.<= nil, 'value' }.to raise_exception NilKey
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
    expect(Registry.subtags).to be_a Hash
  end

  describe '.subtags' do
    it "returns the subtags" do
      expect(Registry.subtags.map { |key, value| value.class }.uniq).to eq [Subtag, Array]
    end

    it "returns 8835 subtags" do
      expect(Registry.subtags.count).to eq 8835
    end

    it "returns 9070 entries" do
      count = Registry.subtags.inject(0) do |total, entry|
        subtag = entry.last
        total + if subtag.is_a? Subtag then 1 else subtag.count end
      end
      expect(count).to eq 9070
    end

    it "returns actual subtags" do
      expect(Registry['Hant']).to be_a Subtag
    end

    it "wraps lines" do
      allow(Net::HTTP).to receive(:get).and_return interlingua
      Registry.class_variable_set :@@subtags, nil
      subtags = Registry.subtags
      expect(subtags.first.last.descriptions.first).to eq 'Interlingua (International Auxiliary Language Association)'
      Registry.class_variable_set :@@subtags, nil
    end

    it "caches the result" do
      Registry.subtags
      expect(Registry.class_variable_get(:@@subtags).count).to eq 8835
    end

    it "only opens the registry file once" do
      Registry.class_variable_set :@@subtags, nil
      expect(Net::HTTP).to receive(:get).exactly(:once).and_return("File-Date: 2018-12-28\n%%\nSubtag: aa\nDescription: Afar")
      Registry.subtags
      Registry.subtags
      Registry.class_variable_set :@@subtags, nil
    end

    it "deals with duplicate entries" do
      expect(Registry['cmn']).to be_an Array
    end
  end

  describe '#[]' do
    it "returns values from the registry hash" do
      german = Registry['de']
      expect(german).to be_a Subtag
      expect(german.code).to eq 'de' # TODO List subtag with ‘de’ as recommended prefix?
      expect(german.descriptions).to eq ['German']
    end

    it "calls .subtags first" do
      expect(Registry).to receive(:subtags).and_return({ 'pt' => Subtag.new(code: 'pt', descriptions: 'Portuguese') })
      Registry['pt']
    end
  end

  describe "sanity checks" do
    it "finds the subtag CS" do
      serbia_and_montenegro = Registry["CS"]
      expect(serbia_and_montenegro.type).to eq "region"
      expect(serbia_and_montenegro.descriptions).to eq ["Serbia and Montenegro"]
    end

    it "finds the subtag cs" do
      czech = Registry["cs"]
      expect(czech.type).to eq "language"
      expect(czech.descriptions).to eq ["Czech"]
    end

    it "finds the subtag Cyrs" do
      cyrillic_ocs = Registry["Cyrs"]
      expect(cyrillic_ocs.type).to eq "script"
      expect(cyrillic_ocs.descriptions).to eq ["Cyrillic (Old Church Slavonic variant)"]
    end

    it "is not buggy" do
      expect(Registry['mo'].scope).to be_nil
    end

    it "really isn’t buggy" do
      bokmål = Registry['nb']
      expect(bokmål.macrolanguage).to eq 'no'
    end

    it "parses the added date" do
      bokmål = Registry['nb']
      expect(bokmål.added).to eq Date.new(2005, 10, 16)
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
    let(:subtag) { Subtag.new }

    it "overwrites simple fields" do
      subtag.flush_stack ['code', "aa"]
      expect(subtag.code).to eq "aa"
    end

    it "adds to cumulative fields" do
      subtag.flush_stack ['description', 'The AA Language']
      expect(subtag.descriptions).to eq ['The AA Language']
    end

    it "doesn’t crash on an empty argument" do
      expect { subtag.flush_stack [] }.not_to raise_exception
    end

    it "doesn’t crash on a nil argument" do
      expect { subtag.flush_stack nil }.not_to raise_exception
    end
  end

  describe '#bureaucratic_name' do
    it "returns the first description entry of the registry" do
      expect(Registry['en'].bureaucratic_name).to eq "English"
      expect(Registry['or'].bureaucratic_name).to eq "Oriya (macrolanguage)"
      expect(Registry['fa'].bureaucratic_name).to eq "Persian"
    end
  end
end

describe Tag do
  describe '#bureaucratic_name' do
    it "combines the subtags’ bureaucratic names" do
      expect(Tag.new('en-us').bureaucratic_name).to eq "English, United States"
      expect(Tag.new('de-1901').bureaucratic_name).to eq "German, Traditional German orthography"
      expect(Tag.new('el-polytonic').bureaucratic_name).to eq "Greek, Polytonic Greek"
      expect(Tag.new('mn-cyrl').bureaucratic_name).to eq "Mongolian, Cyrillic"
    end
  end
end
