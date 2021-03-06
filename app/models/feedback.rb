class Feedback < ActiveRecord::Base
  TWITTER = 1
  BLOG    = 2

  OTHER    = 0
  NEGATIVE = 1
  MIXED    = 2
  POSITIVE = 3
  
  belongs_to :project
  serialize  :description
  
  named_scope :sentiment, lambda { |source, polarity|
    if polarity == 'all'
      {:conditions => { :source => source_name2int(source), :hidden => nil } }
    else
      {:conditions => { :source => source_name2int(source), :hidden => nil, :polarity => polarity_name2int(polarity) } }
    end
  }
  
  def html_description
    result = ''
    description.each {|s|
      result << "<span class='#{polarity_int2name(s[0])}'>#{s[1]}</span>"
    }
    return result 
  end
  
  def text_description
    result = ''
    description.each {|s|
      result << s[1]
    }
    return result 
  end
  
  def reply_url
    return nil if source == Feedback::BLOG
    "http://twitter.com/home?status=@#{author_id}"
  end
  
  def author_id
  end
  
  def reclassify
    require RAILS_ROOT + '/jobs/classifier.rb'
    sentiment_classifier = SentimentClassifier.new
    polarity, content = sentiment_classifier.process(self.text_description)
    self.polarity = polarity
    self.description = content
    self.save!
  end
  
private
  def polarity_int2name i
    case i
    when NEGATIVE
      'negative'
    when MIXED
      'mixed'
    when POSITIVE
      'positive'
    else
      'other'
    end
  end
  
  def self.source_name2int source
    case source
    when 'twitter'
      TWITTER
    else
      BLOG
    end
  end
  
  def self.polarity_name2int name
    case name
    when 'negative'
      NEGATIVE
    when 'mixed'
      MIXED
    when 'positive'
      POSITIVE
    else
      OTHER
    end
  end
  
  #'msaleem (Muhammad Saleem)' -> msaleem
  def author_id
    author_name.split(' ').first
  end
end
