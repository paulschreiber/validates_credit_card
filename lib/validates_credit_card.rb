module ActiveRecord::Validations::ClassMethods
  DEFAULT_CREDIT_CARD_TYPES = {:visa => 'Visa', :mastercard => 'MasterCard', :discover => 'Discover', :amex => 'American Express', :diners => 'Diners Club', :unknown => 'invalid' }
  
  CARD_DATA = {
    :Visa => { :lengths => [13,16], :prefixes => [4] },
    :MasterCard => { :lengths => [16], :prefixes => [51,52,53,54,55] },
    :DinersClub => { :lengths => [14,16], :prefixes => [305,36,38,54,55] },
    :CarteBlanche => { :lengths => [14], :prefixes => [300,301,302,303,304,305] },
    :AmEx => { :lengths => [15], :prefixes => [34,37] },
    :Discover => { :lengths => [16], :prefixes => [6011,622,64,65] },
    :JCB => { :lengths => [16], :prefixes => [35] },
    :enRoute => { :lengths => [15], :prefixes => [2014,2149] },
    :Solo => { :lengths => [16,18,19], :prefixes => [6334, 6767] },
    :Switch => { :lengths => [16,18,19], :prefixes => [4903,4905,4911,4936,564182,633110,6333,6759] },
    :Maestro => { :lengths => [12,13,14,15,16,18,19], :prefixes => [5018,5020,5038,6304,6759,6761] },
    :VisaElectron => { :lengths => [16], :prefixes => [417500,4917,4913,4508,4844] },
    :LaserCard => { :lengths => [16,17,18,19], :prefixes => [6304,6706,6771,6709] },
  }
  
  VALID_OPTION_KEYS = [:if, :unless, :with, :against]
  
  def validate_options(options)
    options.assert_valid_keys(VALID_OPTION_KEYS) unless options.nil?
  end

  def card_type_from_number
    CARD_DATA.each do |card, data|
      data[:prefixes].each do |prefix|
        return card if card_number.to_s.starts_with?(prefix.to_s)
      end
    end # CARD_DATA

    return nil
  end
  
  # I don't think anyone doing the right thing will be validating more than
  # one type and one card number per record.
  def validates_credit_card(*attr_names)
    configuration = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
    validate_options(configuration)
    card_number = attr_names.first
    card_type = attr_names.last

    with = configuration[:with] || DEFAULT_CREDIT_CARD_TYPES
    validates_each(card_number, configuration) do |record, attr_name, value|
      type = record.send(card_type)
      record.errors.add attr_name, "is not a valid #{(type && type.humanize) || 'credit'} card" unless passes_luhn?(value) and with[card_bin(value)] == type
    end
  end

  # example
  # validates_credit_card_type :card_type, :against => :card_number, :with => DEFAULT_CREDIT_CARD_TYPES
  def validates_credit_card_type(*attr_names)
    configuration = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
    validate_options(configuration)
    card_type = attr_names.first

    # TODO: check that the required keys are in this hash.
    with = configuration[:with] || DEFAULT_CREDIT_CARD_TYPE
    against = configuration[:against].to_sym

    validates_each(card_type, configuration) do |record, attr_name, value|
      card_number = record.send(against)
      type = card_bin(card_number)
      record.errors.add attr_name, " is #{value.humanize} but it looks more like a #{with[type].humanize} card." if value != with[type]
    end
  end

  def validates_credit_card_number(*attr_names)
    configuration = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
    validate_options(configuration)
    card_number = attr_names.first
    
    validates_each(card_number, configuration) do |record, attr_name, value|            
      record.errors.add attr_name, 'enter a valid credit card number' unless passes_luhn?(value)
    end
  end

  private 

  def passes_luhn?(number)
    #Luhn check from http://blog.internautdesign.com/2007/4/18/ruby-luhn-check-aka-mod-10-formula
    odd = true
    number.to_s.gsub(/\D/,'').reverse.split('').map(&:to_i).collect { |d|
      d *= 2 if odd = !odd
      d > 9 ? d - 9 : d
    }.sum % 10 == 0
  end

  def passes_bin?(type, number)
    type == card_bin(number)
  end

  def card_bin(card_number)
    if card_number =~ /^4/ and [13,16].include?(card_number.size)
      :visa
    elsif card_number =~ /^5[1-5]/ and card_number.size == 16
      :mastercard
    elsif card_number =~ /^34|37/ and card_number.size == 15
      :amex
    elsif card_number =~ /^6011|65/ and card_number.size == 16
      :discover
    #can't find enough info on these...
    #elsif card_number =~ /^36/ and card_number.size == 16
    #  :diners
    else
      :unknown
    end
  end

end
