class SetDefaultFlagsToStores < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    ActiveRecord::Base.transaction do
      sql = <<-SQL
        ALTER TABLE stores
          ALTER COLUMN flags SET DEFAULT 0
      SQL
      execute(sql)
    end

    max_id = Stores::Store.select("max(id) as max_id").to_a.last[:max_id] || 0
    return unless max_id > 0

    batch_size = 100_000

    (0..max_id).step(batch_size).each do |from_id|
      to_id = from_id + batch_size
      ActiveRecord::Base.transaction do
        execute <<-SQL
            UPDATE stores
            SET
              flags = 0
            WHERE id BETWEEN #{from_id} AND #{to_id}
        SQL
      end
    end
  end
end
