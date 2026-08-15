# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Shared examples for uniqueness validations.
#
# The neutral examples assert the property WITHOUT depending on the database
# collation (they never vary case or accent), so they are green on both SQLite
# (development) and MariaDB (CI and production). They live in
# spec/models/uniqueness_spec.rb.
#
# The collation examples assert what only a case- and accent-insensitive
# collation produces. SQLite cannot express it, so they run only under MariaDB
# (see spec/models/uniqueness_collation_spec.rb).
#
# Each example creates a valid record through its factory and builds a second
# one colliding only on the attribute under test. The factory sequences every
# other unique attribute, so the collision is isolated to that single column.

# Neutral: an exact duplicate of the attribute is rejected.
# `value` defaults to the factory's own value; pass it only when the factory
# leaves the attribute blank or nil (then uniqueness would not even trigger).
RSpec.shared_examples "a unique attribute" do |factory, attribute, value = nil|
  it "rejects a duplicate #{attribute}" do
    overrides = value.nil? ? {} : { attribute => value }
    original = FactoryBot.create(factory, **overrides)
    duplicate = FactoryBot.build(factory, attribute => original.public_send(attribute))
    expect(duplicate).to be_invalid
    expect(duplicate.errors).to be_of_kind(attribute, :taken)
  end
end

# Neutral: uniqueness holds within a scope but not across scopes.
RSpec.shared_examples "a unique attribute scoped to" do |factory, attribute, scope, value|
  it "rejects a duplicate #{attribute} within the same #{scope}" do
    original = FactoryBot.create(factory, attribute => value)
    duplicate = FactoryBot.build(
      factory, attribute => value, scope => original.public_send(scope)
    )
    expect(duplicate).to be_invalid
    expect(duplicate.errors).to be_of_kind(attribute, :taken)
  end

  it "allows the same #{attribute} in a different #{scope}" do
    FactoryBot.create(factory, attribute => value)
    # The factory builds a fresh scope association, so this is a different scope.
    expect(FactoryBot.build(factory, attribute => value)).to be_valid
  end
end

# Neutral: a blank value is exempt from uniqueness (allow_blank/allow_nil).
RSpec.shared_examples "an optional unique attribute" do |factory, attribute, blank = ""|
  it "allows several records with a blank #{attribute}" do
    FactoryBot.create(factory, attribute => blank)
    expect(FactoryBot.build(factory, attribute => blank)).to be_valid
  end
end

# Collation (MariaDB only): the same value in a different case is a duplicate.
# `value` defaults to the factory's own value; pass it only when the factory
# leaves the attribute blank.
RSpec.shared_examples "a case-insensitive attribute" do |factory, attribute, value = nil, scope = nil|
  it "treats #{attribute} as case-insensitive" do
    original = value.nil? ? FactoryBot.create(factory) : FactoryBot.create(factory, attribute => value)
    overrides = { attribute => original.public_send(attribute).upcase }
    overrides[scope] = original.public_send(scope) if scope
    expect(FactoryBot.build(factory, **overrides)).to be_invalid
  end
end

# Collation (MariaDB only): the same value without accents is a duplicate.
RSpec.shared_examples "an accent-insensitive attribute" do |factory, attribute, accented, plain, scope = nil|
  it "treats #{attribute} as accent-insensitive" do
    original = FactoryBot.create(factory, attribute => accented)
    overrides = { attribute => plain }
    overrides[scope] = original.public_send(scope) if scope
    expect(FactoryBot.build(factory, **overrides)).to be_invalid
  end
end
