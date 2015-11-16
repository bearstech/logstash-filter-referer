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
      expect(subject).to include("social")
      expect(subject['social']).to eq('Twitter')
    end
  end
end
