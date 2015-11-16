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

  end # def register

  public
  def filter(event)

    ref = event[@source]
    if ref != "-"
      ref = URI(ref)
      soc = @social[ref.host]
      if soc
        event["social"] = soc
      end
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Example
