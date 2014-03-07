describe 'TwitterStatus' do

  before do
    class << self
      include CDQ
    end
    cdq.setup
  end

  after do
    cdq.reset!
  end

  it 'should be a TwitterStatus entity' do
    TwitterStatus.entity_description.name.should == 'TwitterStatus'
  end
end
