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

  private
  def index(host)
    s = @searchEnginesIndex[host]
    return s if s
    n = host.split '.'
    s = %w[com org net co it edu].include?(n[-2]) ?
      @searchEnginesIndexPrefix[n.slice(0..-3).join '.'] :
      @searchEnginesIndexPrefix[n.slice(0..-2).join '.']
    return s if s
    %w[com org net co it edu].include?(n[0]) ?
      @searchEnginesIndexSufix[n.slice(2..-1).join '.'] :
      @searchEnginesIndexSufix[n.slice(1..-1).join '.']
  end

  public
  def filter(event)
    ref = event[@source]
    if ref != "-"
      ref = URI(ref)
      host = ref.host
      host = host.slice(4..-1) if host.start_with? 'www.'
      if soc = @social[host]
        event["social"] = soc
      else
        if s = index(host)
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
