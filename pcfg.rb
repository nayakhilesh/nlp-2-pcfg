# Coursera NLP class
# Akhilesh Nayak
# Assignment 2
# 4/10/2013

require 'json'
require 'optparse'


def add_freq(tree,freq_hash)
  if tree.is_a?(String)
    if freq_hash.has_key?(tree)
      freq_hash[tree] += 1
    else 
      freq_hash[tree] = 1
    end
  else 
    add_freq(tree[1],freq_hash)
    add_freq(tree[2],freq_hash) unless tree[2] == nil
  end
end

def create_replaced_tree(tree,infrequent_words)
  replaced_tree = []
  if tree.is_a?(String)
    if infrequent_words.has_key?(tree)
      return '_RARE_'
    else 
      return tree
    end
  else
    replaced_tree << tree[0] << create_replaced_tree(tree[1],infrequent_words) 
    replaced_tree << create_replaced_tree(tree[2],infrequent_words) unless tree[2] == nil
  end
  return replaced_tree
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
  
    opts.banner = 'Usage: pcfg.rb --replacefile FILE --countsfile FILE --inputfile FILE'
    
    options[:replace_file] = nil
    opts.on('-r', '--replacefile FILE', 'File to replace infrequent words with _RARE_') do |filename|
      options[:replace_file] = filename
    end
    
    options[:counts_file] = nil
    opts.on('-c', '--countsfile FILE', 'File with rule counts') do |filename|
      options[:counts_file] = filename
    end
    
    options[:input_file] = nil
    opts.on('-i', '--inputfile FILE', 'File to create parse trees for') do |filename|
      options[:input_file] = filename
    end
    
    opts.on('-h', '--help', 'Display this screen') do
     puts opts
     exit
    end
    
  end
  
  optparse.parse!
  #p options

  unless options[:replace_file] == nil
  
    freq_hash = {}
    File.open(options[:replace_file], 'r').each_line do |line|
      #puts line
      tree = JSON.parse(line)
      add_freq(tree,freq_hash)
    end
    
    #p freq_hash
    
    infrequent_words = freq_hash.reject { |word, freq| freq >= 5 }
    #p infrequent_words
    
    File.open(options[:replace_file] + '.replaced', 'w') do |file|
      File.open(options[:replace_file], 'r').each_line do |line|
        #puts line
        tree = JSON.parse(line)
        replaced_tree = create_replaced_tree(tree,infrequent_words)
        file.write(replaced_tree.to_json)
        file.write("\n")
      end
    end
    
  end

  unless options[:counts_file] == nil
  
    nonterminal_count = {}
    unaryrule_count = {}
    binaryrule_count = {}
    File.open(options[:counts_file], 'r').each_line do |line|
      arr = line.split
      if arr[1] == 'NONTERMINAL'
        nonterminal_count[arr[2]] = arr[0]
      elsif arr[1] == 'UNARYRULE'
        unaryrule_count[[arr[2],arr[3]].freeze] = arr[0]
      elsif arr[1] == 'BINARYRULE'
        binaryrule_count[[arr[2],arr[3],arr[4]].freeze] = arr[0]
      else 
        raise 'unknown tag: ' + arr[1]
      end
    end
    
    p nonterminal_count
    p unaryrule_count
    p binaryrule_count
    
  end

end

if __FILE__ == $0
  main
end