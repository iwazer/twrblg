describe 'ImageCache' do

  before do
    class << self
      include CDQ
    end
    cdq.setup
  end

  after do
    cdq.reset!
  end

  it 'should be a ImageCache entity' do
    ImageCache.entity_description.name.should == 'ImageCache'
  end
end
