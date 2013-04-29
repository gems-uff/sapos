require "spec_helper"

describe User do
  let(:user) { User.new }
  subject { user }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "name is not null and is unique" do
          user.name = "Username"
          user.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          user.name = nil
          user.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Username"
          FactoryGirl.create(:user, :name => name)
          user.name = name
          user.should have_error(:taken).on :name
        end
      end
    end
    describe "password_must_be_present" do
      context "should be valid when" do
        it "hashed_password is not null" do
          user.hashed_password = "password"
          user.should have(0).errors_on :password
        end
      end
      context "should have error missing_password when" do
        it "hashed_password is null" do
          user.hashed_password = nil
          user.should have_error(:missing_password).on :password
        end
      end
    end

    describe "before_destroy" do
      context "should be false when" do
        it "user is trying to delete himself" do
          user = FactoryGirl.create(:user)
          User.set_current_user_id(user.id)
          User.stub!(:count).and_return(2)
          user.destroy.should be_false
        end
        it "user is the last on the database" do
          user = FactoryGirl.create(:user)
          user.stub!(:current_user_id).and_return(user.id + 1)
          User.stub!(:count).and_return(1)
          user.destroy.should be_false
        end
      end
    end

  end
  describe "Methods" do
    describe "self.authenticate" do
      context "should return the user when" do
        it "hashed_password matches with encrypted password" do
          user = FactoryGirl.create(:user)
          User.stub!(:encrypt_password).and_return(user.hashed_password)
          User.authenticate(user.name, user.password).should eql(user)
        end
      end
      context "should return nil when" do
        it "hashed_password does not match with encrypted password" do
          user = FactoryGirl.create(:user)
          User.stub!(:encrypt_password).and_return("not user password")
          User.authenticate(user.name, user.password).should be_nil
        end
      end
    end
  end
end