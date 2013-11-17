#encoding: UTF-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

RSpec::Matchers.define :be_able_to_be_destroyed do 

  match do |actual|
    delete_success = true
    obj = FactoryGirl.create(actual.class.name.underscore.to_sym)
    begin
      obj.destroy
      delete_success = obj.destroyed?
    rescue ActiveRecord::DeleteRestrictionError
      delete_success = false
    end
    delete_success
  end

  failure_message_for_should do |actual|
    "It should be possible to delete a #{actual.class.name} record"
  end

  failure_message_for_should_not do |actual|
    "It should not be possible to delete a #{actual.class.name} record"
  end

end


RSpec::Matchers.define :restrict_destroy_when_exists do |dependent_class|

  @fk = nil

  chain :with_fk do |fk|
    @fk = fk
  end

  match do |actual|
    name = actual.class.name.underscore
    @fk = (name + '_id').to_sym if @fk.nil? 

    restrict_success = true

    obj = FactoryGirl.create(name.to_sym)
    FactoryGirl.create(dependent_class, @fk=> obj.id)
    begin
      obj.destroy
      restrict_success = false if obj.destroyed?
    rescue ActiveRecord::DeleteRestrictionError
    end    
    restrict_success
  end

  failure_message_for_should do |actual|
    "destroy should be restricted when there is a #{dependent_class}"
  end

  failure_message_for_should_not do |record|
    "destroy should not be restricted when there is a #{dependent_class}"
  end

end

RSpec::Matchers.define :destroy_dependent do |dependent_class|

  @fk = nil

  chain :with_fk do |fk|
    @fk = fk
  end

  match do |actual|
    name = actual.class.name.underscore
    @fk = (name + '_id').to_sym if @fk.nil? 

    destroy_success = true

    obj = FactoryGirl.create(name.to_sym)
    dependent = FactoryGirl.create(dependent_class, @fk => obj.id)
    begin
      obj.destroy
      dependent.reload
      destroy_success = obj.destroyed? && dependent.destroyed?
    rescue ActiveRecord::DeleteRestrictionError
      destroy_success = false
    rescue ActiveRecord::RecordNotFound
      destroy_success = obj.destroyed? 
    end    
    destroy_success
  end

  failure_message_for_should do |actual|
    "destroy should be propagated to #{dependent_class}"
  end

  failure_message_for_should_not do |record|
    "destroy should be propagated to #{dependent_class}"
  end

end