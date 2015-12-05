# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "yaml"
require "uri"

# Referer plugin get information from the referer field in http logs.
# This plugin can tell if a website is "social" or "search engine".
# For Search engine, the query is extracted.
#
# Patterns came from the Piwik project :
# see <https://github.com/piwik/searchengine-and-social-list>
class LogStash::Filters::Referer < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   referer {
  #     source => "referer"
  #   }
  # }
  #
  config_name 'referer'

  # The field containing the referer url
  config :source, :validate => :string, :required => true

  # Specify the field into which Logstash should store the referer data.
  config :target, :validate => :string, :default => 'referer'

  public
  def register
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
        if urls = engine['urls']
          urls.each_with_index do |url, index|
            if url.end_with? '.{}'
              @searchEnginesIndexPrefix[url.slice 0..-4] = [key, index]
              next
            end
            if url.start_with? '{}.'
              @searchEnginesIndexSufix[url.slice 3..-1] = [key, index]
              next
            end
            @searchEnginesIndex[url] = [key, index]
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
    event[@target] = {"raw" => ref }
    if ref != "-"
      ref = URI(ref)
      host = ref.host
      host = host.slice(4..-1) if host.start_with? 'www.'
      if soc = @social[host]
        event[@target]["social"] = {"raw" => soc}
      else
        if s = index(host)
          name, index = s
          event[@target]["searchengine"] = {"name" => {"raw" => name}}
          engine = @searchEngines[name][index - 1]
          query = Hash[URI::decode_www_form(ref.query)] if ref.query
          engine["params"].each do |param|
            if param.start_with? '/'
              m = Regexp.new(param.slice(1..-2)).match(ref.path)
              p = m[1] if m
            else
              p = query[param] if query
            end
            if p
              event[@target]["searchengine"]["query"] = {"raw" => p}
              break
            end
          end
        end
      end
    end
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Referer
