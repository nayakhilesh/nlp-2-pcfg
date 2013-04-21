# Coursera NLP class
# Akhilesh Nayak
# Assignment 2
# 4/10/2013

require 'json'
require 'optparse'

def write_replaced_file(filename)

  freq_hash = get_freq_hash(filename)
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

def get_freq_hash(filename)
  freq_hash = {}
  File.open(filename, 'r').each_line do |line|
    #puts line
    tree = JSON.parse(line)
    add_freq(tree,freq_hash)
  end
  return freq_hash
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

  attr_accessor :nonterminal_count, :binary_rules, :unary_rules 
                                                    # TODO remove
  def initialize(counts_file,frequent_words)
    @nonterminal_count = {}
    @unaryrule_count = {}
    @binaryrule_count = {}
    @binary_rules = {}
    @unary_rules = {}
    @frequent_words = frequent_words
    File.open(counts_file, 'r').each_line do |line|
      arr = line.split
      if arr[1] == 'NONTERMINAL'
        @nonterminal_count[arr[2].freeze] = arr[0].to_i
      elsif arr[1] == 'UNARYRULE'
        @unaryrule_count[[arr[2],arr[3]].freeze] = arr[0].to_i
        if @unary_rules.has_key?(arr[2])
          @unary_rules[arr[2].freeze] << arr[3]
        else
          @unary_rules[arr[2].freeze] = [arr[3]]
        end
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
      # unary rule
      if @frequent_words.has_key?(y)
        if @unaryrule_count.has_key?([x,y])
          @unaryrule_count[[x,y]]/@nonterminal_count[x].to_f
        else
         nil
        end
      elsif @unaryrule_count.has_key?([x,'_RARE_'])
        @unaryrule_count[[x,'_RARE_']]/@nonterminal_count[x].to_f
      else 
        nil
      end
    # binary rule 
    elsif @binaryrule_count.has_key?([x,y,z])
      @binaryrule_count[[x,y,z]]/@nonterminal_count[x].to_f
    else
      nil
    end
  end

end

def cky_algorithm(sentence,estimator)

  #p sentence
  #cap_n = estimator.nonterminal_count.keys
  n = sentence.length
  # initialization
  pi = {}
  (1..n).each do |i|
    estimator.unary_rules.keys.each do |cap_x|
      q = estimator.estimate(cap_x,sentence[i-1])
      if q != nil
        puts sentence[i-1] + ' ' + cap_x + ' ' + q.to_s
        pi[[i,i,cap_x].freeze] = q
      end
    end
  end
  #p pi
  #exit
  
  #cap_r = estimator.binary_rules
  bp = {}
  # algorithm
  (1..(n-1)).each do |l|
    puts 'length=' + l.to_s
    (1..(n-l)).each do |i|
      j = i+l
      puts 'from %d to %d' %[i,j]
      max = -1.0
      (i..(j-1)).each do |s|
        puts 'for split (%d,%d),(%d,%d)' %[i,s,s+1,j]
        estimator.binary_rules.keys.each do |cap_x|
      
        # calculating max here
        
          estimator.binary_rules[cap_x].each do |cap_yz|
            cap_y = cap_yz[0]
            cap_z = cap_yz[1]
            
              
            if pi.has_key?([i,s,cap_y]) and pi.has_key?([s+1,j,cap_z])
              val = estimator.estimate(cap_x,cap_y,cap_z) *
                    pi[[i,s,cap_y]] *
                    pi[[s+1,j,cap_z]]
              puts 'prob=%.15f, q(%s,%s,%s)=%.15f, pi(%d,%d,%s)=%.15f, pi(%d,%d,%s)=%.15f' %[val,cap_x,cap_y,
              cap_z,estimator.estimate(cap_x,cap_y,cap_z),i,s,cap_y,pi[[i,s,cap_y]],s+1,j,cap_z,pi[[s+1,j,cap_z]]]
              if val > max
                pi[[i,j,cap_x].freeze] = val
                bp[[i,j,cap_x].freeze] = [cap_y,cap_z,s]
                max = val
              end
            end
          end
        end

        if max < -0.99 and max > -1.01
            puts 'No valid rules found'
        end

      end
         
    end
  end
  #p pi
  #p bp
  
  p create_tree(1,n,'SBARQ',bp,sentence)
  
end

def create_tree(start,_end,tag,bp,sentence)
  if start == _end
    return [tag,sentence[start-1]]
  end
  arr = bp[[start,_end,tag]]
  y = arr[0]
  z = arr[1]
  s = arr[2]
  tree = [tag,create_tree(start,s,y,bp,sentence),create_tree(s+1,_end,z,bp,sentence)]
  return tree
end

def usage
  'Usage: pcfg.rb [--writereplaced --trainingfile FILE] | [--trainingfile FILE --countsfile FILE --inputfile FILE]'
end

def parse_options

  options = {}
  optparse = OptionParser.new do |opts|
  
    opts.banner = usage
    
    options[:write_replaced] = false
    opts.on('-w', '--writereplaced', 'Write file \'($trainingfile).replaced\' with infrequent words in $trainingfile replaced with _RARE_') do
     options[:write_replaced] = true
    end
    
    options[:training_file] = nil
    opts.on('-t', '--trainingfile FILE', 'File with training data') do |filename|
      options[:training_file] = filename
    end
    
    options[:counts_file] = nil
    opts.on('-c', '--countsfile FILE', 'File with rule counts derived from \'($trainingfile).replaced\'') do |filename|
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
  return options
  
end

def main
  
  options = parse_options
  #p options

  if options[:write_replaced]
    if options[:training_file]
      write_replaced_file(options[:training_file])
    else
     puts usage
     exit
    end
  else
    if options[:training_file] and options[:counts_file] and options[:input_file]
      
      freq_hash = get_freq_hash(options[:training_file])
      frequent_words = freq_hash.reject { |word, freq| freq < 5 }  
      
      estimator = MaxLikelihoodEstimator.new(options[:counts_file],frequent_words)
    
      #p estimator.estimate('VP','PP','NP')
      #p estimator.estimate('ADVP+ADV','blech')
      #p estimator.estimate('ADVP+ADV','gagagoogoo')
    
      # TODO - is freeze needed?
    
      sentence = 'What are geckos ?'
      cky_algorithm(sentence.split,estimator) 
  
    else
      puts usage
      exit
    end
  end
  
end

if __FILE__ == $0
  main
end