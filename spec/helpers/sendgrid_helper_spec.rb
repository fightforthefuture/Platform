require 'spec_helper'

describe SendgridHelper do
  include SendgridHelper

  describe '#sendgrid_email_stats' do
    it 'survives the Sengrid API being down' do
      expect(Net::HTTP).to receive(:get).and_raise(Timeout::Error)
      expect(sendgrid_email_stats('14')).to be nil
    end
  end
end
