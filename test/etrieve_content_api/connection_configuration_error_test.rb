require_relative '../test_helper'

describe EtrieveContentApi::ConnectionConfigurationError do
  it 'should subclass StandardError' do
    EtrieveContentApi::ConnectionConfigurationError.ancestors.must_include(
      StandardError
    )
  end
end
