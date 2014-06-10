class TwitterStatus < CDQManagedObject
  extend DateFormat
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
    cdq.save
  end

  class << self
    def to_id n, diff=0
      sprintf("%024d", n.to_i * 10 - diff)
    end

    def from_api list_id, hash
      status_id = hash["id"].to_i
      id = to_id(status_id)
      exists = where(id: id).first
      return exists if exists
      profile_image_url = if hash["user"] && hash["user"]["profile_image_url"]
                            hash["user"]["profile_image_url"]
                          end
      TwitterStatus.new(id: id,
                        list_id: list_id.to_i, status_id: status_id.to_i,
                        created_at: parse_dt(hash["created_at"]),
                        user_id: hash["user"]["name"], display_name: hash["user"]["screen_name"],
                        profile_image_url: profile_image_url,
                        text: hash["text"]).tap{|_| _.original = hash}
    end

    def create_gap list_id, status_id, diff=1
      id = to_id(status_id, diff)
      unless TwitterStatus.where(id: id).first
        status = nil
        status = TwitterStatus.create(id: id, list_id: list_id.to_i,
                                      created_at: nil, processed: true,
                                      text: "fetch for non-acquisition...")
        cdq.save
        status
      end
    end

    def max_id list_id
      status = where(list_id: list_id.to_i).sort_by(:id, :descending).first
      if status
        status.status_id
      end
    end

    def load_statuses list_id, complete
      complete.call(where(list_id: list_id.to_i).sort_by(:id, :descending).limit(LOAD_COUNT).all.to_a.clone)
      cdq.save
    end

    def store_statuses array
      array.each_with_index do |status, i|
        for_upd = where(id: status.id).first
        if for_upd
          for_upd.original = status.original
          array[i] = for_upd
        else
          status.stored = true
        end
      end
      cdq.save
    end
  end

end
