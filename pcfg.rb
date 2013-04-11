# Coursera NLP class
# Akhilesh Nayak
# Assignment 2
# 4/10/2013

require 'json'
require 'optparse'


def main
  options = {}
  optparse = OptionParser.new do |opts|
  
    opts.banner = 'Usage: pcfg.rb --file FILENAME'
    
    options[:filename] = nil
    opts.on('-f', '--file FILENAME', 'Input File') do |filename|
      options[:filename] = filename
    end
    
    opts.on('-h', '--help', 'Display this screen') do
     puts opts
     exit
    end
    
  end
  
  optparse.parse!
  p options

  File.open(options[:filename], 'r').each_line do |line|
    #puts line
    tree = JSON.parse(line)
    element = tree[2][1][1][1]
    p element
    p element.is_a?(String)
  end

end

if __FILE__ == $0
  main
end