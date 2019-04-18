require_relative '../test_helper'

describe EtrieveContentApi::AuthenticationError do
  it 'should subclass StandardError' do
    EtrieveContentApi::AuthenticationError.ancestors.must_include StandardError
  end
end
