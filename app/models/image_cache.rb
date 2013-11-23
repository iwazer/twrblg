class ImageCache < NanoStore::Model
  attribute :url
  attribute :data
  attribute :created_at
  attribute :referred_at
end
