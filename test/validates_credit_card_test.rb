require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/validations'

require File.dirname(__FILE__) + '/../lib/validates_credit_card'

class ValidatesCreditCardTest < Test::Unit::TestCase
  include ActiveRecord::Validations::ClassMethods

  def test_visa
    %w[4111111111111111 4012888888881881 4222222222222].each do |ccn|
      assert_credit_card(:visa, ccn)
    end
  end

  def test_diner
    #can't find enough info on these...
    #%w[30569309025904 38520000023237].each do |ccn|
    #  assert_credit_card(:diner, ccn)
    #end
  end
  
  def test_master_card
    %w[5555555555554444 5105105105105100].each do |ccn|
      assert_credit_card(:master_card, ccn)
    end
  end
  
  def test_amex
    %w[378282246310005 371449635398431 378734493671000].each do |ccn|
      assert_credit_card(:amex, ccn)
    end
  end
  
  def test_discover
    %w[6011111111111117 6011000990139424].each do |ccn|
      assert_credit_card(:discover, ccn)
    end
  end

  private

  def assert_credit_card(type, number)
    assert passes_luhn?(number), "#{number} did not pass Luhn checksum"
    assert passes_bin?(type.to_sym, number), "#{number} is not a #{type.to_s.humanize} card"
  end
  
end
