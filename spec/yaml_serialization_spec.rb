require 'spec_helper'

describe Runner::Serialization::Yaml::Serializer do
  before do
    @serializer = Runner::Serialization::Yaml::Serializer
  end
  
  it "should serialize and load serialied data" do
    @serializer.load(@serializer.dump("Hello there"))
  end
end