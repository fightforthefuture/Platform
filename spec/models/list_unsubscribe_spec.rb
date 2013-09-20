require "spec_helper"
require 'cancan/matchers'

describe ListUnsubscribe do

  describe "unsubscribe_hash" do
    it "should create the same has every time" do
      movement = create(:movement, :name => "Save the fails!")
      ListUnsubscribe.unsubscribe_hash(1, 1, movement).should == ListUnsubscribe.unsubscribe_hash(1, 1, movement)
    end

    it "should allow false as the batch number" do
      movement = create(:movement, :name => "Save the fails!")
      ListUnsubscribe.unsubscribe_hash(1, false, movement).should == ListUnsubscribe.unsubscribe_hash(1, false, movement)
    end

    it "should create different hashes given different arguments" do
      movement = create(:movement, :name => "Save the fails!")
      ListUnsubscribe.unsubscribe_hash(1, false, movement).should_not == ListUnsubscribe.unsubscribe_hash(2, 1, movement)
    end

  end

  describe "encode_unsubscribe_email_address" do
    it "should contain the base email, email ID, and hash" do
      movement = create(:movement, :name => "Save the fails!")
      email = create(:email)

      address = ListUnsubscribe.encode_unsubscribe_email_address(email, 1, movement)
      address.should =~ /[a-z]*+#{email.id}_1_[a-f0-9]{32}@[a-z.]*/
    end
  end

  describe "valid_unsubscribe_email_address?" do
    it "should accept valid email addresses" do
      movement = create(:movement, :name => "Save the fails!")
      user = create(:user, movement_id: movement.id, email: "foo@example.com")
      email = create(:email)
      pse = PushSentEmail.new(movement_id: movement.id, user_id: user.id, push_id: email.push.id, email_id: email.id, batch_number: 1).save!

      address = ListUnsubscribe.encode_unsubscribe_email_address(email, 1, movement)
      ListUnsubscribe.valid_unsubscribe_email_address?(address, user.email, movement).should be_true
    end

    it "should reject invalid email addresses" do
      movement = create(:movement, :name => "Save the fails!")
      user = create(:user, movement_id: movement.id, email: "foo@example.com")
      ListUnsubscribe.valid_unsubscribe_email_address?("plain@example.com", user.email, movement).should be_false
      ListUnsubscribe.valid_unsubscribe_email_address?("name+id@example.com", user.email, movement).should be_false
      ListUnsubscribe.valid_unsubscribe_email_address?("bad-hash+21_0e21498c2b287d0b9958296d5c8fb961@example.com", user.email, movement).should be_false
    end
  end

end
