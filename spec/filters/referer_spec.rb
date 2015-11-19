# encoding: utf-8
require 'spec_helper'
require "logstash/filters/referer"

describe LogStash::Filters::Referer do
  describe "Set to Hello World" do
    let(:config) do <<-CONFIG
      filter {
        referer {
          source => "referer"
        }
      }
    CONFIG
    end

    sample("referer" => "http://twitter.com/bearstech/") do
      expect(subject).to include("referer")
      expect(subject['referer']).to include("social")
      expect(subject['referer']['social']['raw']).to eq('Twitter')
    end
    sample("referer" => "https://ecosia.org/search?q=carotte") do
      expect(subject).to include("referer")
      expect(subject["referer"]).to include("searchengine")
      expect(subject['referer']['searchengine']['name']['raw']).to eq('Ecosia')
    end
    sample("referer" => "https://www.google.co.uk/search?q=carotte") do
      expect(subject).to include("referer")
      expect(subject["referer"]).to include("searchengine")
      expect(subject['referer']['searchengine']['name']['raw']).to eq('Google')
      expect(subject['referer']['searchengine']['query']['raw']).to eq('carotte')
    end
    sample("referer" => "http://www.blekko.com/ws/carotte") do
      expect(subject).to include("referer")
      expect(subject["referer"]).to include("searchengine")
      expect(subject['referer']['searchengine']['name']['raw']).to eq('blekko')
      expect(subject['referer']['searchengine']['query']['raw']).to eq('carotte')
    end
  end
end
