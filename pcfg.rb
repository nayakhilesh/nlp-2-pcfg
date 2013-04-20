# Coursera NLP class
# Akhilesh Nayak
# Assignment 2
# 4/10/2013

require 'json'
require 'optparse'

def write_replaced_file(filename)

  freq_hash = {}
  File.open(filename, 'r').each_line do |line|
    #puts line
    tree = JSON.parse(line)
    add_freq(tree,freq_hash)
  end
  
  #p freq_hash
  
  infrequent_words = freq_hash.reject { |word, freq| freq >= 5 }
  #p infrequent_words
  
  File.open(filename + '.replaced', 'w') do |file|
    File.open(filename, 'r').each_line do |line|
      #puts line
      tree = JSON.parse(line)
      replaced_tree = create_replaced_tree(tree,infrequent_words)
      file.write(replaced_tree.to_json)
      file.write("\n")
    end
  end

end

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

class MaxLikelihoodEstimator

  attr_accessor :nonterminal_count, :binary_rules 
  
  def initialize(counts_file)
    @nonterminal_count = {}
    @unaryrule_count = {}
    @binaryrule_count = {}
    @binary_rules = {}
    File.open(counts_file, 'r').each_line do |line|
      arr = line.split
      if arr[1] == 'NONTERMINAL'
        @nonterminal_count[arr[2].freeze] = arr[0].to_i
      elsif arr[1] == 'UNARYRULE'
        @unaryrule_count[[arr[2],arr[3]].freeze] = arr[0].to_i
      elsif arr[1] == 'BINARYRULE'
        @binaryrule_count[[arr[2],arr[3],arr[4]].freeze] = arr[0].to_i
        if @binary_rules.has_key?(arr[2])
          @binary_rules[arr[2].freeze] << [arr[3],arr[4]]
        else
          @binary_rules[arr[2].freeze] = [[arr[3],arr[4]]]
        end
      else 
        raise 'unknown tag: ' + arr[1]
      end
    end
    
    #p @nonterminal_count
    #p @unaryrule_count
    #p @binaryrule_count
    #p @binary_rules
  end
  
  def estimate(x,y,z=nil)
    if z == nil
      if @unaryrule_count.has_key?([x,y])
        @unaryrule_count[[x,y]]/@nonterminal_count[x].to_f
      elsif @unaryrule_count.has_key?([x,'_RARE_'])
        @unaryrule_count[[x,'_RARE_']]/@nonterminal_count[x].to_f
      else 
        nil
      end
    elsif @binaryrule_count.has_key?([x,y,z])
      @binaryrule_count[[x,y,z]]/@nonterminal_count[x].to_f
    else
      nil
    end
  end

end

def cky_algorithm(sentence,estimator)

  #p sentence
  cap_n = estimator.nonterminal_count.keys
  n = sentence.length
  # initialization
  pi = {}
  (1..n).each do |i|
    cap_n.each do |cap_x|
      q = estimator.estimate(cap_x,sentence[i-1])
      pi[[i,i,cap_x].freeze] = (q == nil) ? 0.0 : q
    end
  end
  #p pi
  
  cap_r = estimator.binary_rules
  # algorithm
  (1..(n-1)).each do |l|
    (1..(n-l)).each do |i|
      j = i+l
      cap_n.each do |cap_x|
      
        # calculating max here
        if cap_r[cap_x] != nil
          max = 0.0
          cap_r[cap_x].each do |cap_yz|
            cap_y = cap_yz[0]
            cap_z = cap_yz[1]
            (i..(j-1)).each do |s|
              puts 'new'
              p estimator.estimate(cap_x,cap_y,cap_z)
              p pi[[i,s,cap_y]]
              p pi[[s+1,j,cap_z]]
              val = estimator.estimate(cap_x,cap_y,cap_z) * pi[[i,s,cap_y]] * pi[[s+1,j,cap_z]]
              if val > max
                pi[[i,j,cap_x]] = val
                max = val
              end
            end
          end
        end
        
      end
    end
  end
  p pi
  
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
  
    opts.banner = 'Usage: pcfg.rb --replacefile FILE --countsfile FILE --inputfile FILE'
    
    options[:replace_file] = nil
    opts.on('-r', '--replacefile FILE', 'File with training data to replace infrequent words with _RARE_') do |filename|
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
    write_replaced_file(options[:replace_file])    
  end

  unless options[:counts_file] == nil
    estimator = MaxLikelihoodEstimator.new(options[:counts_file])
  end
  
  p estimator.estimate('VP','PP','NP')
  p estimator.estimate('ADVP+ADV','blech')
  p estimator.estimate('ADVP+ADV','gagagoogoo')
  
  cky_algorithm(%w(hello there again),estimator)

end

if __FILE__ == $0
  main
end