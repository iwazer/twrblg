
schema "0001 initial" do

  entity "ImageCache" do

    string :url, optional: false
    binary :data, optional: false
    datetime :created_at, optional: false
    datetime :referred_at, optional: false

  end

  entity "TwitterStatus" do
    string :id, optional: false
    integer64 :list_id
    integer64 :status_id
    datetime :created_at
    string :profile_image_url
    string :image_url
    string :text
    string :link
    boolean :processed, default: false
  end

end
