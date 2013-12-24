class TwitterStatus < NanoStore::Model
  attribute :list_id
  attribute :status_id
  attribute :status

  LOAD_COUNT = 50

  class << self
    def max_id list_id
      status = find({list_id: list_id.to_i}, {sort: {status_id: :desc}}).first
      if status
        status.status_id
      end
    end

    def load_statuses list_id, complete
      Dispatch::Queue.concurrent.async {
        complete.call(find({list_id: list_id.to_i}, {sort: {status_id: :desc}}).first(LOAD_COUNT))
      }
    end

    def store_statuses list_id, statuses
      statuses.each do |status|
        for_upd = find({status_id: status["id".to_i]}).first
        if for_upd
          for_upd["status"] = status
          for_upd.save
        else
          create(list_id: list_id.to_i, status_id: status["id"].to_i,
                 status: status.merge("_stored" => true))
        end
      end
    end
  end
end
