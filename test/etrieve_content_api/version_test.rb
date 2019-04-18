require_relative '../test_helper'

describe EtrieveContentApi::Version do
  it 'must match format' do
    EtrieveContentApi::Version::VERSION.must_match(/\d+\.\d+\.\d+/)
  end
end
