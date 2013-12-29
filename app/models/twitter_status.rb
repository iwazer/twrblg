class TwitterStatus < NanoStore::Model
  extend DateFormat

  attribute :id
  attribute :list_id
  attribute :status_id
  attribute :created_at
  attribute :profile_image_url
  attribute :image_url
  attribute :text
  attribute :link
  attribute :processed

  LOAD_COUNT = 50

  attr_accessor :original

  def gap?
    id.to_i % 10 > 0
  end

  def below_me_max
    (id.to_i / 10).to_i - 1
  end

  def done
    self.processed = true
    self.save
  end

  class << self
    def to_id n, diff=0
      sprintf("%024d", n.to_i * 10 - diff)
    end

    def from_api list_id, hash
      status_id = hash["id"].to_i
      id = to_id(status_id)
      exists = find({id: id}).first
      return exists if exists
      profile_image_url = if hash["user"] && hash["user"]["profile_image_url"]
                            hash["user"]["profile_image_url"]
                          end
      TwitterStatus.new(id: id,
                        list_id: list_id.to_i, status_id: status_id.to_i,
                        created_at: parse_dt(hash["created_at"]),
                        profile_image_url: profile_image_url,
                        text: hash["text"]).tap{|_| _.original = hash}
    end

    def create_gap list_id, status_id, diff=1
      TwitterStatus.create(id: to_id(status_id, diff),
                           list_id: list_id.to_i,
                           processed: true,
                           text: "fetch for non-acquisition...")
    end

    def max_id list_id
      status = find({list_id: list_id.to_i}, {sort: {id: :desc}}).first
      if status
        status.status_id
      end
    end

    def load_statuses list_id, complete
      Dispatch::Queue.concurrent.async {
        complete.call(find({list_id: list_id.to_i}, {sort: {id: :desc}}).first(LOAD_COUNT))
      }
    end

    def store_statuses array
      array.each_with_index do |status, i|
        for_upd = find({id: status.id}).first
        if for_upd
          for_upd.original = status.original
          puts "update: #{for_upd.id}"
          for_upd.save
          array[i] = for_upd
        else
          status.stored = true
          puts "create: #{status.id}"
          status.save
        end
      end
    end
  end
end
