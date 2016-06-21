require 'nokogiri'
require 'open-uri'
require 'net/http'

class String
  def has_multibytes?
    self.bytes do |byte|
      return true if (byte & 0b10000000) != 0
    end
    false
  end
end

if ARGV.size == 1
  versions = "2.7"
  DICT_NAME = ARGV[0].to_s
elsif ARGV.size == 2
  DICT_NAME = ARGV[0].to_s
  versions = ARGV[1].to_s
else
  puts "Argument error"
  exit
end

BASE_URL = "http://docs.python.jp/" + versions + '/'.freeze
INDEX_URL = BASE_URL + 'genindex.html'.freeze

res = Net::HTTP.get_response(URI.parse(INDEX_URL))
if res.code != '200'
  puts "status error : " + res.code
  exit
end

index = Nokogiri::HTML(open(INDEX_URL))
link_tags = index.xpath('//div[@class="genindex-jumpbox"]')

items = []
link_tags.search('//p[position()=1]//a').each do |tag|
  urls = URI.escape(BASE_URL + tag[:href])
  doc = Nokogiri::HTML(open(urls))
  doc.search('.//table[@class="indextable"]//a[position()=1]').each do |item|
      item = item.text.split[0]
      unless item.match(/^[-.:(]|,$/)
        items << item if !item.has_multibytes?
      end
  end
end

File.open(DICT_NAME, 'w') do |f|
  items.uniq!.sort!
  items.each { |item| f.puts(item) }
end

