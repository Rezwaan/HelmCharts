class UpdateDeliveryTypeForOrders < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def up
    ActiveRecord::Base.transaction do
      sql = <<-SQL
        ALTER TABLE orders
          ALTER COLUMN delivery_type SET DEFAULT 1
      SQL
      execute(sql)
    end

    begin
    max_id = Orders::Order.select('max(id) as max_id').to_a.last[:max_id] || 0
    if max_id > 0
      batch_size = 100_000
      (0..max_id).step(batch_size).each do |from_id|
        to_id = from_id + batch_size
        ActiveRecord::Base.transaction do
          execute <<-SQL
            UPDATE orders
            SET
              delivery_type = 1
            WHERE id BETWEEN #{from_id} AND #{to_id}
          SQL
        end
      end
    end
    rescue => e
      puts e
    end
  end
end
