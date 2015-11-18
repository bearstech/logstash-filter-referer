# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "yaml"
require "uri"

# https://github.com/piwik/searchengine-and-social-list

# This example filter will replace the contents of the default
# message field with whatever you specify in the configuration.
#
# It is only intended to be used as an example.
class LogStash::Filters::Referer < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   example {
  #     message => "My message..."
  #   }
  # }
  #
  config_name "referer"

  config :source, :validate => :string, :required => true

  public
  def register
    # Add instance variables
    path = ::File.expand_path('../../../vendor/Socials.yml', ::File.dirname(__FILE__))
    @social = Hash.new
    YAML.load(File.open(path, 'r').read).each do |key, values|
      values.each do |value|
        @social[value] = key
      end
    end
    path = ::File.expand_path('../../../vendor/SearchEngines.yml', ::File.dirname(__FILE__))
    @searchEnginesIndex = Hash.new
    @searchEnginesIndexPrefix = Hash.new
    @searchEnginesIndexSufix = Hash.new
    @searchEngines = YAML.load(File.open(path, 'r').read)
    @searchEngines.each do |key, engines|
      engines.each do |engine|
        urls = engine['urls']
        if urls
          urls.each_with_index do |url, index|
            if url.end_with? '.{}'
              @searchEnginesIndexPrefix[url.slice 0..-4] = [key, index]
            else
              if url.start_with? '{}.'
                @searchEnginesIndexSufix[url.slice 3..-1] = [key, index]
              else
                @searchEnginesIndex[url] = [key, index]
              end
            end
          end
        end
      end
    end

  end # def register

  public
  def filter(event)
    ref = event[@source]
    if ref != "-"
      ref = URI(ref)
      host = ref.host
      host = host.slice(4..-1) if host.start_with? 'www.'
      soc = @social[host]
      if soc
        event["social"] = soc
      else
        s = @searchEnginesIndex[host]
        if ! s
          n = host.split '.'
          if ['com', 'org', 'net', 'co', 'it', 'edu'].index n[-2]
            s = @searchEnginesIndexPrefix[n.slice(0..-3).join '.']
          else
            s = @searchEnginesIndexPrefix[n.slice(0..-2).join '.']
          end
          if ! s
            if ['com', 'org', 'net', 'co', 'it', 'edu'].index n[0]
              s = @searchEnginesIndexSufix[n.slice(2..-1).join '.']
            else
              s = @searchEnginesIndexSufix[n.slice(1..-1).join '.']
            end
          end
        end
        if s
          name, index = s
          engine = @searchEngines[name][index]
          event["searchengine"] = name
        end
      end
    end
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Example
